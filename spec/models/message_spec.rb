# frozen_string_literal: true

describe Message, :postgres do
  describe ".unread" do
    let!(:message) { create(:message) }

    it "returns messages where read_at is nil" do
      expect(described_class.unread.count).to eq(1)
    end
  end

  describe "#detail" do
    let!(:message) { create(:message, detail: create(:appeal)) }

    it "allows us to optionally associate another object" do
      expect(message.detail).to be_a(Appeal)
    end
  end
end
