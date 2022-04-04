require "spec_helper"

class EncryptedTypeDummy
  include Xmlenc::Builder::ComplexTypes::EncryptedType

  tag "EncryptedData"
end

describe Xmlenc::Builder::ComplexTypes::EncryptedType do

  let(:xml) { File.read File.join("spec", "fixtures", "encrypted_document.xml") }
  subject   { EncryptedTypeDummy.new.parse(xml, :single => true) }

  describe "required fields" do
    it "should have the cipher data field" do
      expect(subject).to respond_to :cipher_data
    end

    it "should check the presence of cipher data" do
      subject.cipher_data = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:cipher_data].size).to eq(1)
    end
  end

  describe "optional fields" do
    [:encryption_method, :key_info].each do |field|
      it "should have the #{field} field" do
        expect(subject).to respond_to field
      end

      it "should allow #{field} to be blank" do
        subject.send("#{field}=", nil)
        expect(subject).to be_valid
      end
    end
  end

  describe "#set_key_name" do
    it "sets the key info with the key name" do
      subject.set_key_name("key name")
      expect(subject.key_info.key_name).to eq "key name"
    end

    it "does not override old key info data" do
      subject.set_key_name("key name")
      expect(subject.key_info.encrypted_key).not_to be_nil
    end

    it "does not set the key info element if the keyname is nil" do
      subject.key_info = nil
      subject.set_key_name(nil)
      expect(subject.key_info).to be_nil
    end
  end

  describe "#parse" do
    describe "encryption method" do
      it "should create an EncryptionMethod element" do
        expect(subject.encryption_method).to be_a Xmlenc::Builder::EncryptionMethod
      end

      it "should parse the algorithm" do
        expect(subject.encryption_method.algorithm).to eq "http://www.w3.org/2001/04/xmlenc#aes128-cbc"
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
        expect(cipher_value).to eq "u2vogkwlvFqeknJ0lYTBZkWS/eX8LR1fDPFMfyK1/UY0EyZfHvbONfDHcC/HLv/faAOOO2Y0GqsknP0LYT1OznkiJrzx134cmJCgbyrYXd3Mp21Pq3rs66JJ34Qt3/+IEyJBUSMT8TdT3fBD44BtOqH2op/hy2g3hQPFZul4GiHBEnNJL/4nU1yad3bMvtABmzhx80lJvPGLcruj5V77WMvkvZfoeEqMq4qPWK02ZURsJsq0iZcJDi39NB7OCiON"
      end
    end
  end
end
