require 'spec_helper'

describe 'Phaos compatibility tests' do
  let(:plain_xml) { File.read('spec/fixtures/phaos/payment.xml') }
  let(:private_key) { OpenSSL::PKey::RSA.new(File.read('spec/fixtures/phaos/rsa-priv-key.pem')) }
  let(:doc) { Nokogiri::XML::Document.parse(encrypted_xml) }

  describe 'element 3des rsa oaep sha1' do
    let(:encrypted_xml) { File.read('spec/fixtures/phaos/enc-element-3des-kt-rsa_oaep_sha1.xml') }

    it 'decrypts the correct element' do
      key_cipher  = Base64.decode64(doc.at_xpath('//xenc:EncryptedKey//xenc:CipherValue', Xmlenc::NAMESPACES).content)
      data_cipher = Base64.decode64(doc.at_xpath('//xenc:EncryptedData/xenc:CipherData/xenc:CipherValue', Xmlenc::NAMESPACES).content)

      key = private_key.private_decrypt(key_cipher, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)

      cipher = OpenSSL::Cipher.new('des-ede3-cbc')
      cipher.decrypt
      cipher.key = key
      cipher.iv  = data_cipher[0...cipher.iv_len]
      result     = cipher.update(data_cipher[cipher.iv_len..-1])
      result << cipher.final

      doc.at_xpath('//xenc:EncryptedData', Xmlenc::NAMESPACES).replace(result)
      expect(doc.to_xml.chomp).to be == plain_xml
    end
  end

  describe 'element aes 128 cbc rsa oaep sha1' do
    let(:encrypted_xml) { File.read('spec/fixtures/phaos/enc-element-aes128-kt-rsa_oaep_sha1.xml') }

    it 'decrypts the correct element' do
      key_cipher  = Base64.decode64(doc.at_xpath('//xenc:EncryptedKey//xenc:CipherValue', Xmlenc::NAMESPACES).content)
      data_cipher = Base64.decode64(doc.at_xpath('//xenc:EncryptedData/xenc:CipherData/xenc:CipherValue', Xmlenc::NAMESPACES).content)

      key = private_key.private_decrypt(key_cipher, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)

      cipher = OpenSSL::Cipher.new('aes-128-cbc')
      cipher.decrypt
      cipher.key = key
      cipher.iv  = data_cipher[0...cipher.iv_len]
      result     = cipher.update(data_cipher[cipher.iv_len..-1])
      result << cipher.final

      doc.at_xpath('//xenc:EncryptedData', Xmlenc::NAMESPACES).replace(result)
      expect(doc.to_xml.chomp).to be == plain_xml
    end
  end

  describe 'element aes 128 cbc rsa 1.5' do
    let(:encrypted_xml) { File.read('spec/fixtures/phaos/enc-element-aes128-kt-rsa1_5.xml') }

    it 'decrypts the correct element' do
      key_cipher  = Base64.decode64(doc.at_xpath('//xenc:EncryptedKey//xenc:CipherValue', Xmlenc::NAMESPACES).content)
      data_cipher = Base64.decode64(doc.at_xpath('//xenc:EncryptedData/xenc:CipherData/xenc:CipherValue', Xmlenc::NAMESPACES).content)

      key = private_key.private_decrypt(key_cipher)

      cipher = OpenSSL::Cipher.new('aes-128-cbc')
      cipher.decrypt
      cipher.key = key
      cipher.iv  = data_cipher[0...cipher.iv_len]
      result     = cipher.update(data_cipher[cipher.iv_len..-1])
      result << cipher.final

      doc.at_xpath('//xenc:EncryptedData', Xmlenc::NAMESPACES).replace(result)
      expect(doc.to_xml.chomp).to be == plain_xml
    end
  end

  describe 'content aes 256 cbc rsa oaep sha1' do
    let(:encrypted_xml) { File.read('spec/fixtures/phaos/enc-content-aes256-kt-rsa1_5.xml') }

    it 'decrypts the correct element' do
      key_cipher  = Base64.decode64(doc.at_xpath('//xenc:EncryptedKey//xenc:CipherValue', Xmlenc::NAMESPACES).content)
      data_cipher = Base64.decode64(doc.at_xpath('//xenc:EncryptedData/xenc:CipherData/xenc:CipherValue', Xmlenc::NAMESPACES).content)

      key = private_key.private_decrypt(key_cipher)

      cipher = OpenSSL::Cipher.new('aes-256-cbc')
      cipher.decrypt
      cipher.key = key
      cipher.iv  = data_cipher[0...cipher.iv_len]
      result     = cipher.update(data_cipher[cipher.iv_len..-1])
      result << cipher.final

      doc.at_xpath('//xenc:EncryptedData', Xmlenc::NAMESPACES).replace(Nokogiri::XML::DocumentFragment.parse(result))
      expect(doc.to_xml.chomp).to be == plain_xml
    end
  end

  describe 'text aes 256 cbc rsa oaep sha1' do
    let(:encrypted_xml) { File.read('spec/fixtures/phaos/enc-text-aes256-kt-rsa_oaep_sha1.xml') }

    it 'decrypts the correct element' do
      key_cipher  = Base64.decode64(doc.at_xpath('//xenc:EncryptedKey//xenc:CipherValue', Xmlenc::NAMESPACES).content)
      data_cipher = Base64.decode64(doc.at_xpath('//xenc:EncryptedData/xenc:CipherData/xenc:CipherValue', Xmlenc::NAMESPACES).content)

      key = private_key.private_decrypt(key_cipher, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)

      cipher = OpenSSL::Cipher.new('aes-256-cbc')
      cipher.decrypt
      cipher.key = key
      cipher.iv  = data_cipher[0...cipher.iv_len]
      result     = cipher.update(data_cipher[cipher.iv_len..-1])
      result << cipher.final


      doc.at_xpath('//xenc:EncryptedData', Xmlenc::NAMESPACES).replace(result)

      expect(doc.to_xml.gsub(/[\n\s]/, '')).to be == plain_xml.gsub(/[\n\s]/, '')
    end
  end
end
