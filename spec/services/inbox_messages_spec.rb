# frozen_string_literal: true

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

      message = user.messages.order(created_at: :desc).first

      expect(inbox.messages.first).to eq(message)

      message.update!(read_at: Time.zone.now)

      inbox = described_class.new(user: user.reload, page_size: 10)

      # read messages sort last
      expect(inbox.messages.first).to_not eq(message)
    end
  end

  describe "hiding older messages" do
    before do
      (0..200).step(25) { |age| create(:message, created_at: age.days.ago, user: user) }
    end

    it "hides messages older than the visible duration" do
      inbox = described_class.new(user: user)
      expect(inbox.total).to eq(5)
      expect(inbox.messages.map(&:created_at)).to all(be > 120.days.ago)
    end
  end
end
