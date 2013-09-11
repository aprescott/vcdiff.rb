require "bindata"
require "vcdiff/integer"

module VCDIFF
  class VCDIFFHeader < BinData::Record
    endian :big

    # header{1,2,3,4} is "VCD\0" with the upper bits turned on for "VCD"
    uint8 :header_v, :initial_value => 0xD6, :assert => 0xD6
    uint8 :header_c, :initial_value => 0xC3, :assert => 0xC3
    uint8 :header_d, :initial_value => 0xC4, :assert => 0xC4
    uint8 :header_zero, :initial_value => 0x00, :assert => 0x00

    uint8 :header_indicator, :initial_value => 0
    uint8 :secondary_compressor_id, :onlyif => :secondary_compressor?
    vcdiff_int :custom_codetable_length, :onlyif => :custom_codetable?
    array :code_table_data, :type => :uint8, :onlyif => :custom_codetable?, :initial_length => :custom_codetable_length

    def secondary_compressor?
      header_indicator[0] == 1
    end

    def custom_codetable?
      header_indicator[1] == 1
    end
  end

  class VCDIFFDeltaEncoding < BinData::Record
    endian :big

    vcdiff_int :bytes_remaining # bytes remaining for the delta encoding
    vcdiff_int :target_length # the size of the decoded target file
    uint8 :delta_indicator, :initial_value => 0
    vcdiff_int :add_run_data_length
    vcdiff_int :instructions_length
    vcdiff_int :copy_addresses_length

    array :add_run_data, :type => :uint8, :initial_length => :add_run_data_length
    array :instructions, :type => :uint8, :initial_length => :instructions_length
    array :copy_address_data, :type => :uint8, :initial_length => :copy_addresses_length

    # VCD_DATACOMP bit value, for unmatched ADD and RUN data
    def data_compressed?
      delta_indicator[0] == 1
    end

    # VCD_INSTCOMP bit value, for the delta instructions and accompanying
    # sizes
    def instructions_compressed?
      delta_indicator[1] == 1
    end

    # VCD_ADDRCOMP bit value, for the addresses for the COPY instructions
    def addresses_compressed?
      delta_indicator[2] == 1
    end
  end

  class VCDIFFWindow < BinData::Record
    endian :big

    uint8 :window_indicator, :initial_value => 0, :assert => lambda { !(value[0] == 1 && value[1] == 1) }
    vcdiff_int :source_data_length, :onlyif => lambda { !compressed_only? }
    vcdiff_int :source_data_position, :onlyif => lambda { !compressed_only? }
    vcdiff_delta_encoding :delta_encoding

    # Returns true if VCD_SOURCE is set
    def source_data?
      window_indicator[0] == 1
    end

    # Returns true if VCD_TARGET is set
    def target_data?
      window_indicator[1] == 1
    end

    # If VCD_SOURCE and VCD_TARGET are both 0, then the target file was
    # compressed by itself.
    def compressed_only?
      !source_data? && !target_data?
    end
  end

  class DeltaFile < BinData::Record
    endian :big

    vcdiff_header :header
    rest :windows
  end
end