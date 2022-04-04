require "spec_helper"

describe Xmlenc::Builder::EncryptedData do

  let(:xml) { File.read File.join("spec", "fixtures", "encrypted_document.xml") }
  subject   { described_class.parse(xml, :single => true) }

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

  describe "#parse" do
    it "should create an EncryptedData element" do
      expect(subject).to be_a Xmlenc::Builder::EncryptedData
    end

    it "should parse the id" do
      expect(subject.id).to eq "ED"
    end

    it "should parse the type" do
      expect(subject.type).to eq "http://www.w3.org/2001/04/xmlenc#Element"
    end

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

  describe "#initialize" do
    context 'no id specified' do
      it 'sets a default #id' do
        expect(described_class.new().id).to be_a String
      end

      it 'the default #id should start with a letter or an _' do
        expect(described_class.new.id =~ /^[a-zA-Z_]/).not_to eq nil
      end
    end

    context 'id specified' do
      it 'sets #id to specified id' do
        expect(described_class.new(id: 'TEST').id).to eq 'TEST'
      end
    end
  end

  describe "#encrypt" do
    subject { described_class.new() }

    before { subject.set_encryption_method(algorithm: 'http://www.w3.org/2001/04/xmlenc#aes256-cbc') }

    it 'returns an EncryptedKey' do
      expect(subject.encrypt('TEST')).to be_a Xmlenc::Builder::EncryptedKey
    end

    context "extra key_options are passed" do
      let(:key_options) { { :id => '_SOME_ID', :recipient => 'SOME_RECIPIENT' } }

      before do
        subject.set_encryption_method(algorithm: 'http://www.w3.org/2001/04/xmlenc#aes256-cbc')
        allow_message_expectations_on_nil
        allow(nil).to receive(:add_data_reference)
      end

      it 'and then used to create the EncryptedKey' do
        expect(Xmlenc::Builder::EncryptedKey).to receive(:new).with(hash_including(key_options))
        subject.encrypt('TEST', key_options)
      end

      context 'when a "carried_key_name" is passed' do
        let(:key_options) { { :id => '_SOME_ID', :recipient => 'SOME_RECIPIENT', :carried_key_name => 'CARRIED_KEY_NAME' } }

        it 'sets the carried key name' do
          expect(subject.encrypt('TEST', key_options).carried_key_name).to eq 'CARRIED_KEY_NAME'
        end
      end
    end
  end

  describe '#set_key_retrieval_method' do
    it 'sets the key info with the retrieval method' do
      subject.set_key_retrieval_method 'retrieval_method'
      expect(subject.key_info.retrieval_method).to eq 'retrieval_method'
    end

    it 'does not set the key info element if the "retrieval_method" is nil' do
      subject.key_info = nil
      subject.set_key_retrieval_method(nil)
      expect(subject.key_info).to be_nil
    end
  end

  describe '#set_key_name' do
    it 'sets the key info with the key name' do
      subject.set_key_name 'key_name'
      expect(subject.key_info.key_name).to eq 'key_name'
    end

    it 'does not set the key info element if the "key_name" is nil' do
      subject.key_info = nil
      subject.set_key_name(nil)
      expect(subject.key_info).to be_nil
    end
  end
end
