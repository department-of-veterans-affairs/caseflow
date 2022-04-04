require 'spec_helper'

describe Xmlenc::Algorithms::RSA15 do
  let(:private_key) { OpenSSL::PKey::RSA.new(File.read('spec/fixtures/key.pem')) }
  let(:public_key) { private_key.public_key }
  let(:cipher_value) { Base64.decode64 "cCxxYh3xGBTqlXbhmKxWzNMlHeE28E7vPrMyM5V4T+t1Iy2csj1BoQ7cqBjE\nhqEyEot4WNRYsY7P44mWBKurj2mdWQWgoxHvtITP9AR3JTMxUo3TF5ltW76D\nLDsEvWlEuZKam0PYj6lYPKd4npUULeZyR/rDRrth/wFIBD8vbQlUsBHapNT9\nMbQfSKZemOuTUJL9PNgsosySpKrX564oQw398XsxfTFxi4hqbdqzA/CLL418\nX01hUjIHdyv6XnA298Bmfv9WMPpX05udR4raDv5X8NWxjH00hAhasM3qumxo\nyCT6mAGfqvE23I+OXtrNlUvE9mMjANw4zweCHsOcfw==\n" }
  let(:key) { %w(ba1407b67c847b0a85a33c93286c401d).pack("H*") }


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
      expect(private_key.private_decrypt(encrypted)).to be == key
    end
  end
end
