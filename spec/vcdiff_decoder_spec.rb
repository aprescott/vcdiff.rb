require "spec_helper"

describe VCDIFF::Decoder do
  subject { VCDIFF::Decoder.new("spec/data/source") }

  describe "#decode" do
    it "can decode delta files, given the source, to derive the target" do
      expect(subject.decode(File.new("spec/data/delta"))).to eq(File.read("spec/data/target"))
    end

    it "can decode delta files with copies from source and target" do
      expect(VCDIFF::Decoder.new("spec/data/source_2").decode(File.new("spec/data/delta_2", "rb"))).to eq(File.read("spec/data/target_2", mode: "rb"))
    end

    it "cannot handle a non-zero header indicator" do
      # secondary compressor
      delta = Tempfile.new("secondary_compressor_bit_set")
      content = File.read("spec/data/delta")
      content.setbyte(4, 0x01)
      delta.write(content)
      delta.rewind

      expect { subject.decode(delta) }.to raise_error(NotImplementedError)

      # custom codetable
      delta = Tempfile.new("custom_codetable_bit_set")
      content = File.read("spec/data/delta")
      content.setbyte(4, 0x02)
      delta.write(content)
      delta.rewind

      expect { subject.decode(delta) }.to raise_error(NotImplementedError)
    end
  end
end
