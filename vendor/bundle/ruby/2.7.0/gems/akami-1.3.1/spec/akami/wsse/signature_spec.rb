require 'spec_helper'

describe Akami::WSSE::Signature do

  let(:validator) { Akami::WSSE::VerifySignature.new(xml) }
  let(:xml) { '' }

  let(:fixtures_path) {
    File.join(Bundler.root, 'spec', 'fixtures', 'akami', 'wsse', 'signature' )
  }
  let(:cert_path) { File.join(fixtures_path, 'cert.pem') }
  let(:password) { 'password' }

  let(:signature) {
    Akami::WSSE::Signature.new(
      Akami::WSSE::Certs.new(
        cert_file:            cert_path,
        private_key_file:     cert_path,
        private_key_password: password
      )
    )
  }

  context 'to_token' do
    let(:xml) { fixture('akami/wsse/signature/unsigned.xml') }

    it 'should ignore excessive whitespace' do
      signature.document = xml
      expect(signature.document).not_to include("  ")
    end

  end

end
