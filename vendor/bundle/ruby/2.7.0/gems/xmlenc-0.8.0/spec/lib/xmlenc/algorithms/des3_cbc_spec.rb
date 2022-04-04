require 'spec_helper'

describe Xmlenc::Algorithms::DES3CBC do
  let(:key) { %w(3219e991eccd9186bf75a83ef8982fd0df4558fd1a837aa2).pack('H*') }
  let(:iv) { %w(918eac719c69c915).pack('H*') }
  let(:cipher_value) { Base64.decode64 "kY6scZxpyRXQbaDZp+LbuvSFYgmI3pQrfsrCVt3/9sZzpeUTPXJEatQ5KPOX\nYpJCGid01h/T8PIezic0Ooz/jU+r3kYMKesMYiXin4CXTZYcGhd0TjmOd4kg\n1vlhE8ktWLC7JDzFLPAqXbOug3ghmWunFiUETbGJaF5V4AHIoZrYP+RS3DTL\ngJcATuDeWyOdueqnLefXiCDNqgSTsK4OyNlX0fpUJgKbL+Mhf5vsqxyIqDsS\n/p6cRA==\n" }
  let(:data) { "<CreditCard Currency=\"USD\" Limit=\"5,000\">\r\n    <Number>4019 2445 0277 5567</Number>\r\n    <Issuer>Bank of the Internet</Issuer>\r\n    <Expiration Time=\"04/02\"/>\r\n  </CreditCard>" }
  subject { described_class.setup(key) }

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
