require "spec_helper"

describe Xmlenc::Builder::DataReference do

  let(:xml) { File.read File.join("spec", "fixtures", "template2.xml") }
  subject { described_class.parse(xml, :single => true) }

  describe "#parse" do
    it "should have uri attribute" do
      expect(subject.uri).to eq "ED"
    end
  end
end