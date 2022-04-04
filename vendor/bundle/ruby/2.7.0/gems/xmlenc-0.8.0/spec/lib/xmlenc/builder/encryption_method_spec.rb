require "spec_helper"

describe Xmlenc::Builder::EncryptionMethod do

  let(:xml) { File.read File.join("spec", "fixtures", "encrypted_document.xml") }
  subject   { described_class.parse(xml, :single => true) }

  describe "required fields" do
    it "should have the algorithm field" do
      expect(subject).to respond_to :algorithm
    end

    it "should check the presence of algorithm" do
      subject.algorithm = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:algorithm].size).to eq(1)
    end
  end

  describe "#parse" do
    it "should create an EncryptionMethod" do
      expect(subject).to be_a Xmlenc::Builder::EncryptionMethod
    end

    it "should parse the algorithm" do
      expect(subject.algorithm).to eq "http://www.w3.org/2001/04/xmlenc#aes128-cbc"
    end
  end

  describe "#digest_method" do
    subject { described_class.new() }

    it 'has an empty digest_method' do
      expect(subject.digest_method).to eq nil
    end

    context "digest_method_algorithm given" do
      subject { described_class.new(digest_method_algorithm: 'ALGO') }

      it 'has no empty digest_method' do
        expect(subject.digest_method).not_to eq nil
      end
    end
  end

end
