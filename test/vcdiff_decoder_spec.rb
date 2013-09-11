require "test_helper"

describe VCDIFF::Decoder do
  subject { VCDIFF::Decoder.new("test/data/source") }

  describe "#decode" do
    it "can decode delta files, given the source, to derive the target" do
      subject.decode(File.new("test/data/delta")).should == File.read("test/data/target")
    end

    it "cannot handle a non-zero header indicator" do
      # secondary compressor
      delta = Tempfile.new("secondary_compressor_bit_set")
      content = File.read("test/data/delta")
      content.setbyte(4, 0x01)
      delta.write(content)
      delta.rewind

      expect { subject.decode(delta) }.to raise_error(NotImplementedError)

      # custom codetable
      delta = Tempfile.new("custom_codetable_bit_set")
      content = File.read("test/data/delta")
      content.setbyte(4, 0x02)
      delta.write(content)
      delta.rewind

      expect { subject.decode(delta) }.to raise_error(NotImplementedError)
    end
  end
end