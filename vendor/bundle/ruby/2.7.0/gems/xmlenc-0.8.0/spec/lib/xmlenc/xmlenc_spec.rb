require 'spec_helper'

describe Xmlenc do

  Dir["spec/fixtures/encrypted/*.txt"].each do |document|
    describe "#{document}" do
      let(:encrypted_xml) { Base64.decode64(File.read(document)) }
      let(:encrypted_document) { Xmlenc::EncryptedDocument.new(encrypted_xml) }
      let(:private_key) { OpenSSL::PKey::RSA.new(File.read(document.gsub('.txt', '.pem'))) }

      it "should be validateable" do
        expect {
          @decrypted = encrypted_document.decrypt(private_key)
        }.not_to raise_error
      end
    end
  end
end
