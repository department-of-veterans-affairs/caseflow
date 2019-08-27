# frozen_string_literal: true

require "rails_helper"

describe Message do
  describe ".unread" do
    let!(:message) { create(:message) }

    it "returns messages where read_at is nil" do
      expect(described_class.unread.count).to eq(1)
    end
  end
end
