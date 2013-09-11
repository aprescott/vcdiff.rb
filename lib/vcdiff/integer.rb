require "bindata"

module VCDIFF
  # As described in RFC 3284 (http://tools.ietf.org/html/rfc3284)
  # unsigned integers are treated as a number in base 128.
  # Each digit in this representation is encoded in the lower
  # 7 bits of a byte. Runs of bytes b_1, b_2, b_3, ..., b_n
  # for one integer have the most significant bit set to 1
  # for each b_i, i = 1, ..., n-1, and set to 0 for b_n.
  # 
  # So 123456789 encodes to four 7-bit digits with values
  # 58, 111, 26, 21:
  # 
  #     +-------------------------------------------+
  #     | 10111010 | 11101111 | 10011010 | 00010101 |
  #     +-------------------------------------------+
  #       MSB+58     MSB+111    MSB+26     0+21
  #
  class VCDIFFInt < BinData::BasePrimitive
    def value_to_binary_string(value)
      bytes = []

      loop do
        # get the value of the lowest 7 bits
        next_value = value & 0b01111111

        value >>= 7

        # on every byte except the first one, flip the 8th bit on
        next_value = 0b10000000 | next_value unless bytes.empty?

        bytes.unshift(next_value)

        break if value == 0
      end

      bytes.pack("C*")
    end

    def read_and_return_value(io)
      byte_values = []
      value = 0

      loop do
        b = next_byte(io)
        last_byte = (b[7] == 0)

        byte_values << (b & 0b01111111)

        break if last_byte
      end

      byte_values.reverse.each_with_index do |e, i|
        # add byte * 128**i, since e is considered to be
        # a number in base 128
        value += e * (1 << (7 * i))
      end

      value
    end

    def sensible_default
      0
    end

    # Converts a Ruby Integer into a string where each character is
    # either 0 or 1, fully representing the bytes in the array.
    #
    # TODO: a non-awful method name and non-awful implementation
    def value_to_zero_one_string
      to_binary_s.unpack("C*").map { |e| e.to_s(2).rjust(8, "0") }.join("")
    end

    # Gives the VCDIFF integer as a regular Ruby Integer
    def to_i
      snapshot
    end

    private

    # next byte as a fixnum
    def next_byte(io)
      io.readbytes(1).unpack("C")[0]
    end

    # Returns the lowest multiple of m
    # greater than or equal to n.
    def self.next_multiple(n, m)
      n + (m - n % m) % m
    end
  end
end