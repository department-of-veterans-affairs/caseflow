require "spec_helper"

describe Xmlenc::Builder::DigestMethod do

  let(:xml) { File.read File.join("spec", "fixtures", "template2.xml") }
  subject { described_class.parse(xml, :single => true) }

  describe "#parse" do
    it "should have one algorithm" do
      expect(subject.algorithm).to eq "http://www.w3.org/2000/09/xmldsig#sha1"
    end

    it "raises error when no algorithm" do
      subject.algorithm = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:algorithm].size).to eq(1)
    end
  end
end