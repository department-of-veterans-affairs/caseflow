# frozen_string_literal: true

describe Contention do
  let(:utf8_text) do
    "The claim of entitlement\nto compensation under\r\n38 U.S.C. § 1151\rfor " \
    "¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ is remanded."
  end

  subject { described_class.new(utf8_text) }

  describe "#text" do
    it "truncates description to 255 bytes" do
      expect(utf8_text.length).to eq(177)
      expect(utf8_text.bytesize).to eq(273)
      expect(subject.text.bytesize).to eq(254) # 255 would break a multi-byte codepoint
    end

    it "removes newlines" do
      expect(subject.text).to include("entitlement to compensation under 38 U.S.C. § 1151 for")
      expect(subject.text).not_to include("\n")
      expect(subject.text).not_to include("\r")
    end
  end
end
