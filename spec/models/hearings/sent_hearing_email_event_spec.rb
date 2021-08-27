# frozen_string_literal: true

describe SentHearingEmailEvent do
  # TODO: This will have to be removed once we have a HearingEmailStatusMailer class
  class Hearings::SendSentStatusEmail
    def initialize(**args); end
    def call(**args); end
  end

  context "#create" do
    let(:user) { create(:user) }
    let(:hearing) { create(:hearing) }
    let(:email_type) { "confirmation" }
    let(:recipient_role) { "appellant" }

    subject do
      SentHearingEmailEvent.create(
        hearing: hearing,
        email_type: email_type,
        recipient_role: recipient_role,
        sent_by: user
      )
    end

    it "automatically sets the sent_at date" do
      expect(subject.sent_at).not_to be(nil)
    end

    context "invalid email type field" do
      let(:email_type) { "INVALID" }

      it "fails validation" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "invalid recipient role" do
      let(:recipient_role) { "INVALID" }

      it "fails validation" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  context "#handle_reported_status" do
    let(:sent_hearing_email_event) do
      create(
        :sent_hearing_email_event,
        :with_hearing,
        send_successful_checked_at: DateTime.now
      )
    end

    it "takes one argument." do
      expect { sent_hearing_email_event.handle_reported_status }.to raise_error(ArgumentError)
    end

    it "does nothing if the send_successful is true." do
      status_checked_at_was = sent_hearing_email_event.send_successful_checked_at
      sent_hearing_email_event.update(send_successful: true)

      sent_hearing_email_event.handle_reported_status("sent")

      expect(sent_hearing_email_event.send_successful_checked_at).to eq(status_checked_at_was)
      expect(sent_hearing_email_event.send_successful).to be(true)
    end

    it "updates send_successful_checked_at if the status given is 'new'." do
      status_checked_at_was = sent_hearing_email_event.send_successful_checked_at

      sent_hearing_email_event.handle_reported_status("new")

      expect(sent_hearing_email_event.send_successful_checked_at).to be > status_checked_at_was
      expect(sent_hearing_email_event.send_successful).to be(nil)
      expect(sent_hearing_email_event.sent_hearing_admin_email_events.count).to be(0)
    end

    it "updates send_successful_checked_at if the status given is 'sending'." do
      status_checked_at_was = sent_hearing_email_event.send_successful_checked_at

      sent_hearing_email_event.handle_reported_status("sending")

      expect(sent_hearing_email_event.send_successful_checked_at).to be > status_checked_at_was
      expect(sent_hearing_email_event.send_successful).to be(nil)
      expect(sent_hearing_email_event.sent_hearing_admin_email_events.count).to be(0)
    end

    it "updates send_successful_checked_at and sets send_successful to true when the status is 'sent'." do
      status_checked_at_was = sent_hearing_email_event.send_successful_checked_at

      sent_hearing_email_event.handle_reported_status("sent")

      expect(sent_hearing_email_event.send_successful_checked_at).to be > status_checked_at_was
      expect(sent_hearing_email_event.send_successful).to be(true)
    end

    it "raises InvalidReportedStatus when an invalid status is given." do
      status_checked_at_was = sent_hearing_email_event.send_successful_checked_at
      allow(Raven).to receive(:capture_exception)

      sent_hearing_email_event.handle_reported_status("bananas")

      expect(Raven).to have_received(:capture_exception).with(SentHearingEmailEvent::InvalidReportedStatus)
      expect(sent_hearing_email_event.send_successful_checked_at).to be > status_checked_at_was
    end

    context "failed status" do
      SentHearingEmailEvent::FAILED_EMAIL_REPORTED_SENT_STATUSES.each do |failed_status|
        it "raises SentStatusEmailAlreadySent when #{failed_status} is given a sent_hearing_admin_email_event record exists." do
          status_checked_at_was = sent_hearing_email_event.send_successful_checked_at
          sent_hearing_email_event.sent_hearing_admin_email_events.create

          allow(Raven).to receive(:capture_exception)

          sent_hearing_email_event.handle_reported_status(failed_status)

          expect(Raven).to have_received(:capture_exception).with(SentHearingEmailEvent::SentStatusEmailAlreadySent)
          expect(sent_hearing_email_event.send_successful_checked_at).to be > status_checked_at_was
          expect(sent_hearing_email_event.send_successful).to be(false)
        end

        it "invokes HearingEmailStatusMailer when #{failed_status} is given." do
          status_checked_at_was = sent_hearing_email_event.send_successful_checked_at

          expect(Hearings::SendSentStatusEmail).to receive(:new).once

          sent_hearing_email_event.handle_reported_status(failed_status)

          expect(sent_hearing_email_event.send_successful_checked_at).to be > status_checked_at_was
          expect(sent_hearing_email_event.send_successful).to be(false)
        end

        it "creates a delivery_failure record when #{failed_status} is given." do
          status_checked_at_was = sent_hearing_email_event.send_successful_checked_at

          sent_hearing_email_event.handle_reported_status(failed_status)

          expect(sent_hearing_email_event.delivery_failures.count).to eq(1)
          expect(sent_hearing_email_event.send_successful_checked_at).to be > status_checked_at_was
          expect(sent_hearing_email_event.send_successful).to be(false)
        end
      end
    end
  end
end
