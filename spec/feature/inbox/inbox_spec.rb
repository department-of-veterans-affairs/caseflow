# frozen_string_literal: true

feature "Inbox", :postgres do

  let!(:user) { User.authenticate!(roles: ["Mail Intake"]) }
  let!(:hlr) { create(:higher_level_review, :requires_processing, intake: create(:intake, user: user)) }

  describe "index" do
    context "multiple messages" do
      before do
        user.messages << build(:message, text: "hello world")
        user.messages << build(:message, text: "message with <a href='/intake'>link</a>")
        user.messages << build(:message,
                               created_at: 1.month.ago,
                               text: "i have been read",
                               read_at: Time.zone.now)
      end

      it "show all messages and allows user to mark as read" do
        visit "/inbox"

        expect(page).to have_content("Messages will remain in the intake box for 120 days")
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

        expect(page).to have_content("Read #{message.read_at.friendly_full_format}")
      end
    end

    context "when a job fails after 24 hours" do
      it "displays the failure message" do
        allow(hlr).to receive(:establish!).and_raise(StandardError.new("error with some PII"))
        Timecop.travel(Time.zone.now.tomorrow) do
          DecisionReviewProcessJob.perform_now(hlr)
        end
        visit "/inbox"

        expect(page).to have_content("unable to complete")
        expect(page).not_to have_content("some PII")
      end
    end

    context "when a job succeeds after 24 hours" do
      it "displays the success message" do
        Timecop.travel(Time.zone.now.tomorrow) do
          hlr.processed!
        end
        visit "/inbox"

        expect(page).to have_content("successfully been processed")
      end
    end
  end
end
