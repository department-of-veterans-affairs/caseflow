require 'spec_helper'

describe Xmlenc::Algorithms::AESCBC do
  let(:key) { %w(1e8c108fc0521dcad99ff2daad45af64).pack('H*') }
  let(:iv) { %w(6232242cfaa495554dd5f684b17d6de4).pack('H*') }
  let(:cipher_value) { Base64.decode64 "YjIkLPqklVVN1faEsX1t5EXXxdlW3B0rKoZsT5DtaS+pChdcceQV605clJ8Y\nEhOjEhM0oCGf855bQVWp7J3TJqUFlxahREEWCfEvsIUzy/wNMHV6Z/mTFkQU\nWnrO3C3DSC6rTglijkPp592Sh1Cb6HTD60Nc/Myn3QLnwlSj+30x3uTUiAVE\nL+xduAnppCR1vhRsB3yw32TjRfZt1b+UURRzCts5oLrVAu9SSrmgJI+vUX9g\nsRgvwkmsi4AAq38a\n" }
  let(:data) { "<CreditCard Currency=\"USD\" Limit=\"5,000\">\r\n    <Number>4019 2445 0277 5567</Number>\r\n    <Issuer>Bank of the Internet</Issuer>\r\n    <Expiration Time=\"04/02\"/>\r\n  </CreditCard>" }
  subject { described_class.new(128).setup(key) }

  describe 'encrypt' do
    it 'encrypts the data' do
      allow(subject).to receive(:iv).and_return(iv)
      expect(subject.encrypt(data)).to be == cipher_value
    end
  end

  describe 'decrypt' do
    it 'decrypts the cipher_value' do
      expect(subject.decrypt(cipher_value)).to be == data
    end
  end
end
