require "spec_helper"

describe Xmlenc::Builder::EncryptedKey do

  let(:xml) { File.read File.join("spec", "fixtures", "encrypted_document.xml") }
  subject   { described_class.parse(xml, :single => true) }

  describe "required fields" do
    [:cipher_data].each do |field|
      it "should have the #{field} field" do
        expect(subject).to respond_to :cipher_data
      end

      it "should check the presence of #{field}" do
        subject.cipher_data = nil
        expect(subject).to_not be_valid
        expect(subject.errors[:cipher_data].size).to eq(1)
      end
    end
  end

  describe "optional fields" do
    [:id, :recipient, :encryption_method, :key_info, :carried_key_name].each do |field|
      it "should have the #{field} field" do
        expect(subject).to respond_to field
      end

      it "should allow #{field} to be blank" do
        subject.send("#{field}=", nil)
        expect(subject).to be_valid
      end
    end
  end

  describe "#parse" do
    it "should create an EncryptedKey" do
      expect(subject).to be_a Xmlenc::Builder::EncryptedKey
    end

    it "should have a reference_list" do
      expect(subject.reference_list).to be_a Xmlenc::Builder::ReferenceList
    end

    it 'should have a carried key name' do
      expect(subject.carried_key_name).to eq 'key-name'
    end

    it "should have a data object" do
      expect(subject).to respond_to :data
    end

    describe "encryption method" do
      it "should create an EncryptionMethod element" do
        expect(subject.encryption_method).to be_a Xmlenc::Builder::EncryptionMethod
      end

      it "should parse the algorithm" do
        expect(subject.encryption_method.algorithm).to eq "http://www.w3.org/2001/04/xmlenc#rsa-1_5"
      end
    end

    describe "key info" do
      it "should create a KeyInfo element" do
        expect(subject.key_info).to be_a Xmlenc::Builder::KeyInfo
      end
    end

    describe "cipher data" do
      it "should create a CipherData element" do
        expect(subject.cipher_data).to be_a Xmlenc::Builder::CipherData
      end

      let(:cipher_value) { subject.cipher_data.cipher_value.gsub(/[\n\s]/, "") }

      it "should parse the cipher value" do
        expect(cipher_value).to eq "cCxxYh3xGBTqlXbhmKxWzNMlHeE28E7vPrMyM5V4T+t1Iy2csj1BoQ7cqBjEhqEyEot4WNRYsY7P44mWBKurj2mdWQWgoxHvtITP9AR3JTMxUo3TF5ltW76DLDsEvWlEuZKam0PYj6lYPKd4npUULeZyR/rDRrth/wFIBD8vbQlUsBHapNT9MbQfSKZemOuTUJL9PNgsosySpKrX564oQw398XsxfTFxi4hqbdqzA/CLL418X01hUjIHdyv6XnA298Bmfv9WMPpX05udR4raDv5X8NWxjH00hAhasM3qumxoyCT6mAGfqvE23I+OXtrNlUvE9mMjANw4zweCHsOcfw=="
      end
    end
  end

  describe "#encrypt" do
    it "has method" do
      expect(subject).to respond_to :encrypt
    end
  end

  describe "#add_data_reference" do
    it "has method" do
      expect(subject).to respond_to :add_data_reference
    end

    it "has one data reference" do
      expect(subject.reference_list.data_references.count).to eq 1
    end

    it "adds an extra data reference" do
      subject.add_data_reference(SecureRandom.hex(5))
      expect(subject.reference_list.data_references.count).to eq 2
    end
  end

  describe "#initialize" do
    it 'initializes an EncryptedKey' do
      expect(described_class.new()).to be_a described_class
    end

    context 'with extra options' do
      subject { described_class.new(id: 'AN_ID', recipient: 'A_RECIPIENT') }

      it 'sets @recipient and @id' do
        expect(subject.id).to eq 'AN_ID'
        expect(subject.recipient).to eq 'A_RECIPIENT'
      end
    end
  end
end
