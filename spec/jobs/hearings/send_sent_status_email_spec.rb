# frozen_string_literal: true

describe Hearings::SendSentStatusEmail do
  describe "call" do
    let(:original_recipient_email_address) { "test@caseflow.va.gov" }
    let(:hearing_coordinator_email_address) { "another-test@caseflow.va.gov" }
    let(:sent_by) { create(:user, email: hearing_coordinator_email_address) }
    let(:sent_hearing_email_event) do
      create(
        :sent_hearing_email_event,
        email_address: original_recipient_email_address,
        sent_by: sent_by
      )
    end
    let(:sent_hearing_admin_email_event) do
      create(:sent_hearing_admin_email_event, sent_hearing_email_event: sent_hearing_email_event)
    end
    let(:sender) { described_class.new(sent_hearing_admin_email_event: sent_hearing_admin_email_event) }
    let(:external_message_id) { "id/123423423" }
    subject { sender.call }

    it "will send to the hearing coordinator, not the original recipient" do
      email = HearingEmailStatusMailer.notification(
        sent_hearing_email_event: sent_hearing_email_event
      )
      expect(email.to.first).to eq(sent_by.email)
    end

    it "sends a notification email" do
      # Ensure a call HearingEmailStatusMailer.notification()
      expect(HearingEmailStatusMailer).to receive(:notification).once.and_call_original
      # Mock the external_message_id method
      allow_any_instance_of(described_class).to receive(:get_external_message_id).and_return(external_message_id)
      # Call the sender
      subject
      # SendSentStatusEmail should set the external_message_id
      expect(sent_hearing_admin_email_event.external_message_id).to eq(external_message_id)
    end

    it "fails to send when there is no email on the event" do
      # Remove the email address
      sent_by.update(email: nil)
      # Expect not to generate an email
      expect(HearingEmailStatusMailer).not_to receive(:notification)
      # Expect we logged the failure to Rails.logger
      expect(Rails.logger).to receive(:info)
      # Expect we logged the failure to DataDog
      expect(DataDogService).to receive(:increment_counter)
      # Call the sender
      subject
      # We should not set an external_message_id because we didnt sent an email
      expect(sent_hearing_admin_email_event.external_message_id).to be_falsey
    end
  end
end
