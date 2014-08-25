require "spec_helper"

KNOWN_ENCODINGS = {
                    266478  => "100100001010000101101110",
                    488908  => "100111011110101101001100",
                    1311959 => "110100001000100101010111",
                    290936  => "100100011110000001111000",
                    1306432 => "110011111101111001000000",
                    1318485 => "110100001011110001010101",
                    983071  => "101111001000000000011111",
                    918966  => "101110001000101100110110",
                    1119947 => "110001001010110101001011",
                    1186056 => "110010001011001000001000"
                  }

describe VCDIFF::VCDIFFInt do
  it "converts between different representations" do
    KNOWN_ENCODINGS.each do |int, str|
      packed = [str].pack("B*")

      i = VCDIFF::VCDIFFInt.read(packed)

      expect(i.snapshot).to eq(int)
      expect(i.to_binary_s).to eq(packed)
      expect(i.to_i).to eq(i.snapshot)
    end
  end
end
