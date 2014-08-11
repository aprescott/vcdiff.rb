require "bentley_mcilroy"

require "vcdiff/integer"
require "vcdiff/records"
require "vcdiff/code_table"

module VCDIFF
  class Encoder
    #### Implement me ####
  end

  class Decoder
    attr_accessor :dictionary

    def initialize(dictionary)
      @dictionary = File.read(dictionary, mode: "rb")

      @s_near = 4
      @s_same = 3

      # all cache values initialize to 0
      @near_cache = Array.new(@s_near, 0)
      @same_cache = Array.new(@s_same * 256, 0)
      @next_slot = 0
    end

    # Decodes a delta file using the dictionary given to the decoder
    def decode(file)
      delta_file = DeltaFile.read(File.new(file))

      if delta_file.header.header_indicator != 0
        raise NotImplementedError, "Header indicator of #{delta_file.header.header_indicator} can't be handled"
      end

      if delta_file.header.custom_codetable?
        raise NotImplementedError, "Unable to handle a custom codetable"
      end

      # there's no simple way to determine the number of windows, since the
      # count isn't given ahead of time, so we'll need to manually iterate
      # through the windows
      window_stream = StringIO.new(delta_file.windows)

      target_file = ""

      until window_stream.eof?
        # reads only one window's worth of bytes from the stream
        next_window = VCDIFFWindow.read(window_stream)

        if next_window.compressed_only? || next_window.target_data?
          raise NotImplementedError, "Can only handle VCD_SOURCE windows"
        end

        length, position = next_window.source_data_length, next_window.source_data_position

        source_window = @dictionary[position, length]

        target_file << process_delta_encoding(source_window, next_window.delta_encoding)
      end

      target_file
    end

    # takes a delta encoding and processes it against the source
    # window.
    #
    # this corresponds to section (6) in RFC3284, which outlines
    # processing the instructions, data and addresses arrays.
    def process_delta_encoding(source_window, delta_encoding)
      # to_a is needed here to unwrap the BinData::Array, which doesn't
      # know about method calls like #shift
      instructions      = delta_encoding.instructions.to_a
      add_run_data      = delta_encoding.add_run_data.to_a
      copy_address_data = delta_encoding.copy_address_data.to_a

      code_table = CodeTable::DEFAULT_TABLE

      # the final string for this window
      target_window = ""

      add_run_index = 0

      until instructions.empty?
        # instructions is a sequence of tupes (index, [size1], [size2]),
        # where size1 and size2 existence depends on the instruction entry
        # which _index_ points to.
        index = instructions.shift

        # instruction pair looked up in the code table
        instruction = code_table[index]
        type1, size1, mode1, type2, size2, mode2 = instruction

        if type1 != CodeTable::NOOP && size1 == 0
          instruction_size_1 = read_int(instructions)
        else
          instruction_size_1 = size1
        end

        if type2 != CodeTable::NOOP && size2 == 0
          instruction_size_2 = read_int(instructions)
        else
          instruction_size_2 = size2
        end

        case type1
        when CodeTable::NOOP
          next
        when CodeTable::RUN
          if mode1 != 0
            warn "Warning: RUN found with mode #{mode1} -- value will be ignored"
          end

          if instruction_size_1 == 0
            raise ArgumentError, "File contains a RUN instruction of size 0, must be > 0"
          end

          # repeat a single character instruction_size_1 times.
          # since add_run_data is an array of byte values, we
          # call #[x, 1] with *n to get n copies of the byte
          # at index x, since ary[x, 1] == [ary[x]].
          target_window << (add_run_data[add_run_index, 1] * instruction_size_1).pack("C*")
          add_run_index += 1
        when CodeTable::ADD
          if mode1 != 0
            warn "Warning: ADD found with mode #{mode1} -- value will be ignored"
          end

          if instruction_size_1 == 0
            raise ArgumentError, "File contains an ADD instruction of size 0, must be > 0"
          end

          target_window << (add_run_data[add_run_index, instruction_size_1]).pack("C*")
          add_run_index += instruction_size_1
        when CodeTable::COPY
          # from (5.3) of RFC3284:
          #
          #   The address of a COPY instruction is encoded using different modes,
          #   depending on the type of cached address used, if any.
          #
          #   Let "addr" be the address of a COPY instruction to be decoded and
          #   "here" be the current location in the target data (i.e., the start of
          #   the data about to be encoded or decoded).  Let near[j] be the jth
          #   element in the near cache, and same[k] be the kth element in the same
          #   cache.  Below are the possible address modes:
          #
          #      VCD_SELF: This mode has value 0.  The address was encoded by
          #         itself as an integer.
          #
          #      VCD_HERE: This mode has value 1.  The address was encoded as the
          #         integer value "here - addr".
          #
          #      Near modes: The "near modes" are in the range [2,s_near+1].  Let m
          #         be the mode of the address encoding.  The address was encoded
          #         as the integer value "addr - near[m-2]".
          #
          #      Same modes: The "same modes" are in the range
          #         [s_near+2,s_near+s_same+1].  Let m be the mode of the encoding.
          #         The address was encoded as a single byte b such that "addr ==
          #         same[(m - (s_near+2))*256 + b]".
          #

          here = target_window.length - 1

          case mode1
          when 0 # VCD_SELF
            addr = read_int(copy_address_data)
          when 1 # VCD_HERE
            addr = here - read_int(copy_address_data)
          when 2..(@s_near + 1) # near modes
            addr = read_int(copy_address_data) + @near_cache[mode1 - 2]
          when (@s_near+2)..(@s_near+@s_same+1) # same modes
            # address is encoded as a single byte
            b = copy_address_data.shift
            addr = @same_cache[(mode1 - (@s_near + 2))*256 + b]
          else
            raise ArgumentError, "invalid mode #{mode1}"
          end

          target_window << source_window[addr, instruction_size_1]

          # now update the "near" and "same" caches.
          if @s_near > 0
            @near_cache[@next_slot] = addr
            @next_slot = (@next_slot + 1) % @s_near
          end

          if @s_same > 0
            @same_cache[addr % (@s_same * 256)] = addr
          end
        else
          raise ArgumentError, "Invalid file format, instruction of #{type1} (found at index #{index}) doesn't exist"
        end
      end

      target_window
    end

    # shifts a VCDIFF integer off the given array of bytes, modifying
    # the array argument in-place.
    def read_int(array)
      # first index where the MSB = index-7 bit is 0
      zero_msb_index = array.index { |e| e.to_i[7] == 0 }

      int_bytes = array.shift(zero_msb_index + 1)

      VCDIFFInt.read(int_bytes.pack("C*")).to_i
    end
  end
end
