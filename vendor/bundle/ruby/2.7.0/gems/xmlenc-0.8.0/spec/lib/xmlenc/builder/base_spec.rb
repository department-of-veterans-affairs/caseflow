require "spec_helper"

class BaseDummy
  include Xmlenc::Builder::Base

  tag "tag"
end

describe BaseDummy do
  describe "parse override" do
    it "sets the from_xml flag" do
      expect(BaseDummy.parse("<tag></tag>", :single => true).from_xml?).to be_truthy
    end

    it "raises an error if the message cannot be parsed" do
      expect {
        BaseDummy.parse("invalid")
      }.to raise_error(Xmlenc::UnparseableMessage)
    end

    it "raises an error if the message is nil" do
      expect {
        BaseDummy.parse(nil)
      }.to raise_error(Xmlenc::UnparseableMessage, 'Unable to parse nil document')
    end
  end
end
