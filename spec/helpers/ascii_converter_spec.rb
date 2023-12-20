# frozen_string_literal: true

describe AsciiConverter do
  describe "#convert" do
    subject { described_class.new(string: string).convert }

    context "string contains Windows 1252 codepoint" do
      let(:string) { "O\x92Reilly" }

      it "returns ASCII" do
        expect(subject).to eq("O'Reilly")
      end
    end
  end
end
