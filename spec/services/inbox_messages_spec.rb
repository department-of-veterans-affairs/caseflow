# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe InboxMessages, :postgres do
  let(:user) { create(:user) }

  describe "pagination" do
    before do
      50.times { create(:message, user: user) }
    end

    it "returns slice of messages in correct order" do
      inbox = described_class.new(user: user, page_size: 10)

      expect(inbox.total).to eq(50)
      expect(inbox.messages.count).to eq(10)

      message = user.messages.reload.first

      expect(inbox.messages.first).to eq(message)

      message.update!(read_at: Time.zone.now)

      inbox = described_class.new(user: user.reload, page_size: 10)

      # read messages sort last
      expect(inbox.messages.first).to_not eq(message)
    end
  end
end
