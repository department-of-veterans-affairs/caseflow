require 'spec_helper'

describe Xmlenc::EncryptedKey do
  let(:encrypted_xml) { File.read('spec/fixtures/encrypted_document.xml') }
  let(:doc) { Nokogiri::XML::Document.parse(encrypted_xml) }
  let(:encrypted_key_node) { doc.at_xpath('//xenc:EncryptedKey', Xmlenc::NAMESPACES) }
  let(:private_key) { OpenSSL::PKey::RSA.new(File.read('spec/fixtures/phaos/rsa-priv-key.pem')) }
  subject { described_class.new(encrypted_key_node) }

  describe 'document' do
    it 'returns the nokogiri document' do
      expect(subject.document).to be_a(Nokogiri::XML::Document)
    end
  end

  describe 'encryption_method' do
    it 'returns the encryption method' do
      expect(subject.encryption_method).to be == encrypted_key_node.at_xpath('./xenc:EncryptionMethod', Xmlenc::NAMESPACES)
    end
  end

  describe 'cipher_value' do
    it 'returns the cipher value' do
      expect(subject.cipher_value).to be == <<-CV.gsub(/[\n\s]/, '')
        cCxxYh3xGBTqlXbhmKxWzNMlHeE28E7vPrMyM5V4T+t1Iy2csj1BoQ7cqBjEhqEy
        Eot4WNRYsY7P44mWBKurj2mdWQWgoxHvtITP9AR3JTMxUo3TF5ltW76DLDsEvWlE
        uZKam0PYj6lYPKd4npUULeZyR/rDRrth/wFIBD8vbQlUsBHapNT9MbQfSKZemOuT
        UJL9PNgsosySpKrX564oQw398XsxfTFxi4hqbdqzA/CLL418X01hUjIHdyv6XnA2
        98Bmfv9WMPpX05udR4raDv5X8NWxjH00hAhasM3qumxoyCT6mAGfqvE23I+OXtrN
        lUvE9mMjANw4zweCHsOcfw==
      CV
    end
  end

  describe 'encrypted_data' do
    describe 'with reference list' do
      it 'returns the encrypted data element' do
        expect(subject.encrypted_data).to be_a(Xmlenc::EncryptedData)
      end
    end

    describe 'without reference list' do
      it 'returns the encrypted data element' do
        xml_no_ref =  File.read('spec/fixtures/encrypted_document_no_ref_list.xml')
        no_ref_doc = Nokogiri::XML::Document.parse(xml_no_ref)
        encrypted_no_ref_key_node = no_ref_doc.at_xpath("//xenc:EncryptedKey[@ID='second_key']", Xmlenc::NAMESPACES)
        no_ref_node = Xmlenc::EncryptedKey.new(encrypted_no_ref_key_node)
        expect(no_ref_node.encrypted_data.node['ID']).to be == 'second_data'
      end
    end
  end

  describe 'decrypt' do
    describe 'with rsa 15' do
      it 'returns the decrypted key' do
        expect(subject.decrypt(private_key)).to be == ['ba1407b67c847b0a85a33c93286c401d'].pack('H*')
      end
    end

    describe 'with rsa oaep' do
      before :each do
        allow(subject).to receive(:cipher_value).and_return <<-CV.gsub(/[\n\s]/, '')
          ZF0JPSfv75/8M+O2O/xi+8N1b9KT94a4l1D1Q65hnX6F00t+wAWZSkcDUoD/
          y2/ERKGUyuQwsG6l58e4MwYpmDI4RhHrUYLCQBacAehqVZhwNxv99L7ANsqr
          ZJoT7N0kER9MbmuIZGb4qisLDfZtzIGKKUUiA3ARfQny4MUxFovSmVUF2Ojq
          SBXUVV/PjMLifVTVyqCMv08YwmM4abj33tKOEMtiZqAa09lUIpnCUzq2IASh
          SRNBzWIHe+ndoB6G2p6ufk0TuRidwdQZkZwTW/2PjK1x7KejaqADWaOIImKh
          SBMpGzkVfDuv8aAFXOtf+LV67Ov6hJAt7FB65tE9Hg==
        CV

        fragment = <<-XML
          <EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p" xmlns="http://www.w3.org/2001/04/xmlenc#">
            <ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" xmlns:ds="http://www.w3.org/2000/09/xmldsig#"/>
          </EncryptionMethod>
        XML
        encrypted_key_node.at_xpath('./xenc:EncryptionMethod', Xmlenc::NAMESPACES).replace(Nokogiri::XML::DocumentFragment.parse(fragment)) 
      end

      describe 'with unsupported digest method' do
        it 'raises an unsupported error' do
          fragment = <<-XML
            <EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p" xmlns="http://www.w3.org/2001/04/xmlenc#">
              <ds:DigestMethod Algorithm="unsupported" xmlns:ds="http://www.w3.org/2000/09/xmldsig#"/>
            </EncryptionMethod>
          XML

          encrypted_key_node.at_xpath('./xenc:EncryptionMethod', Xmlenc::NAMESPACES).replace(Nokogiri::XML::DocumentFragment.parse(fragment)) 

          expect {
            subject.decrypt(private_key)
          }.to raise_error(Xmlenc::UnsupportedError)
        end
      end

      it 'returns the decrypted key' do
        expect(subject.decrypt(private_key)).to be == ['3219e991eccd9186bf75a83ef8982fd0df4558fd1a837aa2'].pack('H*')
      end
    end

    describe 'with unsupported algorithm' do
      it 'raises an unsupported error' do
        fragment = <<-XML
          <EncryptionMethod Algorithm="unsupported" xmlns="http://www.w3.org/2001/04/xmlenc#"></EncryptionMethod>
        XML

        encrypted_key_node.at_xpath('./xenc:EncryptionMethod', Xmlenc::NAMESPACES).replace(Nokogiri::XML::DocumentFragment.parse(fragment))

        expect {
          subject.decrypt(private_key)
        }.to raise_error(Xmlenc::UnsupportedError)
      end
    end
  end

  describe 'encrypt' do
    let(:template_doc) { Nokogiri::XML::Document.parse(File.read('spec/fixtures/template.xml')) }
    let(:template2_doc) { Nokogiri::XML::Document.parse(File.read('spec/fixtures/template2.xml')) }
    let(:encrypted_key_template) { described_class.new(template_doc.at_xpath('//xenc:EncryptedKey', Xmlenc::NAMESPACES)) }
    let(:encrypted_key_template2) { described_class.new(template2_doc.at_xpath('//xenc:EncryptedKey', Xmlenc::NAMESPACES)) }
    let(:public_key) { private_key.public_key }
    let(:data) { 'random key' }

    it 'stores the encrypted value in the cipher value' do
      encrypted_key_template.encrypt(public_key, data)
      encrypted_key_template2.encrypt(public_key, data)

      expect(encrypted_key_template.cipher_value.length).to be > 0
      expect(encrypted_key_template2.cipher_value.length).to be > 0
    end

    it 'allows decryption with the key' do
      encrypted_key_template.encrypt(public_key, data)
      encrypted_key_template2.encrypt(public_key, data)

      expect(encrypted_key_template.decrypt(private_key)).to be == data
      expect(encrypted_key_template2.decrypt(private_key)).to be == data
    end
  end

end
