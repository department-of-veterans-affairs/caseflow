require 'spec_helper'

describe Akami::WSSE::Certs do

  let(:private_key_password) {'password' }
  let(:cert_string)          { nil }
  let(:private_key_string)   { nil }

  let(:fixtures_path) do
    File.join(Bundler.root, 'spec', 'fixtures', 'akami', 'wsse', 'signature' )
  end

  let(:subject) do
    Akami::WSSE::Certs.new(
      cert_file:            cert_file_path,
      cert_string:          cert_string,
      private_key_file:     private_key_path,
      private_key_string:   private_key_string,
      private_key_password: private_key_password,
    )
  end

  context 'with a path to a certificate and private key' do
    let(:cert_file_path)   { File.join(fixtures_path, 'cert.pem') }
    let(:private_key_path) { File.join(fixtures_path, 'private_key') }

    it 'should use the certificate path provided' do
      expected_certificate = OpenSSL::X509::Certificate.new(File.read(cert_file_path))
      expect(subject.cert.to_pem).to eq(expected_certificate.to_pem)
    end

    it 'should use the private key path provided' do
      expected_key = OpenSSL::PKey::RSA.new(File.read(private_key_path), private_key_password)
      expect(subject.private_key.to_pem).to eq(expected_key.to_pem)
    end

    context 'with an in-memory cert and private key' do
      let!(:cert_string) { File.read(File.join(fixtures_path, 'cert2.pem')) }
      let!(:private_key_string) { File.read(File.join(fixtures_path, 'private_key2')) }

      it 'should use the strings provided' do
        expected_certificate = OpenSSL::X509::Certificate.new(cert_string).to_pem
        expect(subject.cert.to_pem).to eq(expected_certificate)
      end

      it 'should use the private key provided' do
        expected_key = OpenSSL::PKey::RSA.new(private_key_string, private_key_password)
        expect(subject.private_key.to_pem).to eq(expected_key.to_pem)
      end

    end
  end
end
