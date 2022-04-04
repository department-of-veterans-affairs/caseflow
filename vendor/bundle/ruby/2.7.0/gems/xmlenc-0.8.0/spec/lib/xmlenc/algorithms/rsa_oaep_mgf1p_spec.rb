require 'spec_helper'

describe Xmlenc::Algorithms::RsaOaepMgf1p do
  let(:private_key) { OpenSSL::PKey::RSA.new(File.read('spec/fixtures/key.pem')) }
  let(:public_key) { private_key.public_key }
  let(:cipher_value) { Base64.decode64 "W6N0IhRF2AdgfzzkZSp/u1kH5KmH8L4W8k4mdNMboLsYgnBUV3lsRvoFrVTX\nluMVDtXY1ju7aAEUJP9eMRU676kvRR5nSVuAbWCAejgkHMtGShJHU1s/JMzb\nu3iaxsuyPosT7/iafinNIXumvqLM/WQl9KbsmcWoAmJISbK1+WJ2kahrXNav\n4+7vMJq90BOPl8bXIzeKIsps7OGwEvrFaJ5RzVjZXi9SDXXD1vd6tJBcCfcZ\n347Mat1tZkR3cYrCMhDdte3gYGUQLzUlMYucvWz1slzTX3rYea/vhgA+OLOp\ndZxwM4igx1d8j5jjmo8FR1rxwd0G4NHA1bZ6TOy/IA==\n" }
  let(:key) { %w(1e8c108fc0521dcad99ff2daad45af64).pack("H*") }


  describe 'decrypt' do
    subject { described_class.new(private_key) }

    it 'decrypts the cipher value' do
      expect(subject.decrypt(cipher_value)).to be == key
    end
  end

  describe 'encrypt' do
    subject { described_class.new(public_key) }

    it 'encrypts the key' do
      encrypted = subject.encrypt(key)
      expect(private_key.private_decrypt(encrypted, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)).to be == key
    end
  end
end
