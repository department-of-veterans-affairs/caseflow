require 'spec_helper'

describe Xmlenc::EncryptedData do
  let(:plain_xml) { File.read('spec/fixtures/phaos/payment.xml') }
  let(:encrypted_xml) { File.read('spec/fixtures/encrypted_document.xml') }
  let(:doc) { Nokogiri::XML::Document.parse(encrypted_xml) }
  let(:encrypted_data_node) { doc.at_xpath('//xenc:EncryptedData', Xmlenc::NAMESPACES) }
  let(:key) { %w(ba1407b67c847b0a85a33c93286c401d).pack('H*') }
  subject { described_class.new(encrypted_data_node) }

  describe 'document' do
    it 'returns the nokogiri document' do
      expect(subject.document).to be_a(Nokogiri::XML::Document)
    end
  end

  describe 'encryption_method' do
    it 'returns the encryption method' do
      expect(subject.encryption_method).to be == encrypted_data_node.at_xpath('./xenc:EncryptionMethod', Xmlenc::NAMESPACES)
    end
  end

  describe 'cipher_value' do
    it 'returns the cipher value' do
      expect(subject.cipher_value).to be == <<-CV.gsub(/[\n\s]/, '')
        u2vogkwlvFqeknJ0lYTBZkWS/eX8LR1fDPFMfyK1/UY0EyZfHvbONfDHcC/HLv/f
        aAOOO2Y0GqsknP0LYT1OznkiJrzx134cmJCgbyrYXd3Mp21Pq3rs66JJ34Qt3/+I
        EyJBUSMT8TdT3fBD44BtOqH2op/hy2g3hQPFZul4GiHBEnNJL/4nU1yad3bMvtAB
        mzhx80lJvPGLcruj5V77WMvkvZfoeEqMq4qPWK02ZURsJsq0iZcJDi39NB7OCiON
      CV
    end
  end

  describe 'decrypt' do
    describe 'aes128-cbc' do
      it 'replaces returns the decrypted value' do
        expect(subject.decrypt(key).gsub(/[\n\s]/, '')).to be == <<-XML.gsub(/[\n\s]/, '')
          <CreditCard Currency="USD" Limit="5,000">
            <Number>4019 2445 0277 5567</Number>
            <Issuer>Bank of the Internet</Issuer>
            <Expiration Time="04/02"/>
          </CreditCard>
        XML
      end
    end

    describe 'aes256-cbc' do
      it 'replaces returns the decrypted value' do
        fragment = <<-XML
          <EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes256-cbc" xmlns="http://www.w3.org/2001/04/xmlenc#"></EncryptionMethod>
        XML
        encrypted_data_node.at_xpath('./xenc:EncryptionMethod', Xmlenc::NAMESPACES).replace(Nokogiri::XML::DocumentFragment.parse(fragment))
        allow(subject).to receive(:cipher_value) { 'DpNYC0Np5hHaQAUyHWpM3MQ99wkDFtGRc7TywqxmhI4sJKDXM5SRjVlKf6st5wOz' }
        key = %w(b0621c35317af207b92e3a6b317a122a93772a7261e3f13a4297eb64a91af10a).pack('H*')

        expect(subject.decrypt(key)).to be == '4019 2445 0277 5567'
      end
    end

    describe 'des3-cbc' do
      it 'replaces returns the decrypted value' do
        fragment = <<-XML
            <EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#tripledes-cbc" xmlns="http://www.w3.org/2001/04/xmlenc#"></EncryptionMethod>
        XML

        encrypted_data_node.at_xpath('./xenc:EncryptionMethod', Xmlenc::NAMESPACES).replace(Nokogiri::XML::DocumentFragment.parse(fragment))
        allow(subject).to receive(:cipher_value) { 'kY6scZxpyRXQbaDZp+LbuvSFYgmI3pQrfsrCVt3/9sZzpeUTPXJEatQ5KPOXYpJC
                                      Gid01h/T8PIezic0Ooz/jU+r3kYMKesMYiXin4CXTZYcGhd0TjmOd4kg1vlhE8kt
                                      WLC7JDzFLPAqXbOug3ghmWunFiUETbGJaF5V4AHIoZrYP+RS3DTLgJcATuDeWyOd
                                      ueqnLefXiCDNqgSTsK4OyNlX0fpUJgKbL+Mhf5vsqxyIqDsS/p6cRA==' }

        key = %w(3219e991eccd9186bf75a83ef8982fd0df4558fd1a837aa2).pack('H*')

        expect(subject.decrypt(key).gsub(/[\n\s]/, '')).to be == <<-XML.gsub(/[\n\s]/, '')
            <CreditCard Currency="USD" Limit="5,000">
              <Number>4019 2445 0277 5567</Number>
              <Issuer>Bank of the Internet</Issuer>
              <Expiration Time="04/02"/>
            </CreditCard>
        XML
      end
    end
  end

  describe 'encrypt' do
    let(:template_node) { Nokogiri::XML::Document.parse(File.read('spec/fixtures/template.xml')).root }
    let(:encrypted_data_template) { described_class.new(template_node) }
    let(:data) { subject.decrypt(key) }

    it 'stores the encrypted value in the cipher value' do
      key = encrypted_data_template.encrypt(data)

      expect(encrypted_data_template.cipher_value.length).to be > 0
    end

    it 'allows decryption with the key' do
      key = encrypted_data_template.encrypt(data)

      expect(encrypted_data_template.decrypt(key)).to be == data
    end
  end
end
