require 'spec_helper'

describe Xmlenc::Algorithms::AESGCM do
  let(:data) { "<CreditCard Currency=\"USD\" Limit=\"5,000\">\r\n    <Number>4019 2445 0277 5567</Number>\r\n    <Issuer>Bank of the Internet</Issuer>\r\n    <Expiration Time=\"04/02\"/>\r\n  </CreditCard>" }

  describe 'aes128-gcm' do
    let(:cipher_value) { Base64.decode64 "YjIkLPqklVVN1faEgndPFXgXaOlVVaL+5X8NCDkbgQsbv6D2Jo7d9NQCyMbp1MgU2myCUynzdXMKdVIaqTt14pkr+NtYD6kBFPUkTvbcMIc86L5aqoMIEeqeJCK3aYLNGcY05xxOpuHvMzh2tEoZPFLEd9WgsNGhfv+4GqKiXxMVrjeLp7Iz9dYB4XmfLnQr62m4vYsZpxzg0mkxX6miCDNplv4wVBSwMDCvAFbAoWltKd+upjwaPQDNLIp0GYfQdCr7cu6K0ep4sIc=" }
    let(:key) { %w(1e8c108fc0521dcad99ff2daad45af64).pack('H*') }
    let(:iv) { %w(6232242cfaa495554dd5f684).pack('H*') }
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

  describe 'aes192-gcm' do
    let(:cipher_value) { Base64.decode64 "YjIkLPqklVVN1faETdI41CyJetO9+vdpho9swtvre7VRd5GpkFxp3lioUUlL2URCVx24YMHOzI6ksj0jQxASXn5uvNdIUrOxtTUzzUlIKk2Jbsi6uecP/YNz7NINxz4RqcjxiH+X8IF9etWAjRt+Z2zI/5YaUsQ/kPcrfesUxaH+6aMH9XWDXNqHdCjlxxMTw/4Sj9GqGmdC73CdokggeS8dfF05TZRF4lH2kTZ/RBgS7EEwwXZVKlq6yHfe5Jv2VxHqKJ8f/OSEyiw=" }
    let(:key) { %w(68432eb84dcb27e6cf46cc8d2cb1659484bbea7d0a8131f4).pack('H*') }
    let(:iv) { %w(6232242cfaa495554dd5f684).pack('H*') }
    subject { described_class.new(192).setup(key) }

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

  describe 'aes256-gcm' do
    let(:cipher_value) { Base64.decode64 "YjIkLPqklVVN1faEcqScF7ALyB/fb+q3+HRW17n2rUqvdO8AmI4h7wXOwj5wgeP7KBCuR6IWQK9bUeZE+EoIR+tQNXmN8CofZ6s81QbZEPMiNdRnurXz0LNaSZUL1D1ivic62TYtfgqVX+z7wesGBviRM+vHcfRQlmN5sSzBtgPF9n5u2D6mpG9fa/+I33pAFDy2FeHI1CFPzLzbvKDqnjfM7zDd0YbsNi+5czoWl7likHNplPXR1jhLxOmKPWloKQVEG8f2KHsL/ZI=" }
    let(:key) { %w(7b655b83e4821c9302d24be876b7783b2301b06b4ff89cabe8e9809d7602f207).pack('H*') }
    let(:iv) { %w(6232242cfaa495554dd5f684).pack('H*') }
    subject { described_class.new(256).setup(key) }

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
end
