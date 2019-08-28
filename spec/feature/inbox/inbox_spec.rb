# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

feature "Inbox", :postgres do
  before { FeatureToggle.enable!(:inbox) }
  after { FeatureToggle.disable!(:inbox) }

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
        expect(page).to have_content("Viewing 1-3 of 3 total")

        # mark as read
        message = user.messages.first

        expect(page).to have_button("inbox-message-#{message.id}", disabled: false)

        safe_click "#inbox-message-#{message.id}"

        expect(page).to have_button("inbox-message-#{message.id}", disabled: true)

        expect(message.reload.read_at).to_not be_nil
      end
    end
  end
end
