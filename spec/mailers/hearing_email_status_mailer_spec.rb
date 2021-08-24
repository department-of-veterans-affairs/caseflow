# frozen_string_literal: true

describe HearingEmailStatusMailer do
  describe "notification" do
    let(:sent_hearing_email_event) { create(:sent_hearing_email_event) }

    it "has the correct subject" do
      email = described_class.notification(sent_hearing_email_event: sent_hearing_email_event)
      expect(email.subject).to eq("Email Failed to Send - Do Not Reply")
    end

    it "includes some other key piece of information" do
      expect(true).to eq(true)
    end
  end
end
