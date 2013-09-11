require "test_helper"

describe VCDIFF::CodeTable do
  describe "DEFAULT_TABLE" do
    it "has 256 entries" do
      VCDIFF::CodeTable::DEFAULT_TABLE.length == 256
    end
  end
end