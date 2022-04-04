require "spec_helper"

describe Xmlenc::Builder::ReferenceList do

  let(:xml) { File.read File.join("spec", "fixtures", "template2.xml") }
  subject { described_class.parse(xml, :single => true) }

  describe "#parse" do
    it "has data" do
      expect(subject.data_references.first).to be_a Xmlenc::Builder::DataReference
    end

    it "has function" do
      expect(subject).to respond_to :add_data_reference
    end
  end

  describe "#add_data_reference" do
    it "adds a data reference" do
      subject.add_data_reference(SecureRandom.hex(5))
      expect(subject.data_references.count).to eq 2
    end
  end
end