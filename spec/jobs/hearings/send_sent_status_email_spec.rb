# frozen_string_literal: true

describe Hearings::SendSentStatusEmail do
  describe "call" do
    it "sends a notification email" do
      #let(:sent_hearing_email_event) { create(:sent_hearing_email_event) }
      #let(:mailer) { HearingEmailStatusMailer }
      #allow(mailer).to receive(:notification).and_return(:notification_sent)
      #described_class.new(sent_hearing_email_event: sent_hearing_email_event).call
    end
    it "fails to send when there is no email" do
    end
  end
end
