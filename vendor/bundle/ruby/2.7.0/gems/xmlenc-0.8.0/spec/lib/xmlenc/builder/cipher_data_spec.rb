require "spec_helper"

describe Xmlenc::Builder::CipherData do

  let(:xml) { File.read File.join("spec", "fixtures", "encrypted_document.xml") }
  subject   { described_class.parse(xml) }

  describe "#parse" do
    it "should create two CipherData elements" do
      subject.each do |element|
        expect(element).to be_a Xmlenc::Builder::CipherData
      end

      expect(subject.size).to eq 2
    end

    describe "cipher value" do
      it "should parse the cipher value of the first cipher data element" do
        expect(subject.first.cipher_value.gsub(/[\n\s]/, "")).to eq "cCxxYh3xGBTqlXbhmKxWzNMlHeE28E7vPrMyM5V4T+t1Iy2csj1BoQ7cqBjEhqEyEot4WNRYsY7P44mWBKurj2mdWQWgoxHvtITP9AR3JTMxUo3TF5ltW76DLDsEvWlEuZKam0PYj6lYPKd4npUULeZyR/rDRrth/wFIBD8vbQlUsBHapNT9MbQfSKZemOuTUJL9PNgsosySpKrX564oQw398XsxfTFxi4hqbdqzA/CLL418X01hUjIHdyv6XnA298Bmfv9WMPpX05udR4raDv5X8NWxjH00hAhasM3qumxoyCT6mAGfqvE23I+OXtrNlUvE9mMjANw4zweCHsOcfw=="
      end

      it "should parse the cipher value of the last cipher data element" do
        expect(subject.last.cipher_value.gsub(/[\n\s]/, "")).to eq "u2vogkwlvFqeknJ0lYTBZkWS/eX8LR1fDPFMfyK1/UY0EyZfHvbONfDHcC/HLv/faAOOO2Y0GqsknP0LYT1OznkiJrzx134cmJCgbyrYXd3Mp21Pq3rs66JJ34Qt3/+IEyJBUSMT8TdT3fBD44BtOqH2op/hy2g3hQPFZul4GiHBEnNJL/4nU1yad3bMvtABmzhx80lJvPGLcruj5V77WMvkvZfoeEqMq4qPWK02ZURsJsq0iZcJDi39NB7OCiON"
      end
    end
  end

end
