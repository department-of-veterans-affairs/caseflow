# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

feature "Inbox", :postgres do
  let!(:user) { User.authenticate!(roles: ["Mail Intake"]) }

  describe "index" do
    context "multiple messages" do
      before do
        user.messages << build(:message, text: "hello world")
        user.messages << build(:message, text: "message with <a href='/intake'>link</a>")
        user.messages << build(:message, text: "i have been read", read_at: Time.zone.now)
      end

      it "show all messages and allows user to mark as read" do
        visit "/inbox"

        expect(page).to have_content("hello world")
        expect(page).to have_content("message with link")
        expect(page).to have_link("link")
        expect(page).to have_content("i have been read")
        expect(page).to have_button("inbox-message-#{user.messages.last.id}", disabled: true)

        message = user.messages.first

        safe_click "#inbox-message-#{message.id}"

        expect(page).to have_content("Read #{message.reload.read_at.friendly_full_format}")
      end
    end
  end
end
