# frozen_string_literal: true

describe SentHearingEmailEvent do
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
        sent_status_checked_at: DateTime.now,
        external_message_id: nil
      )
    end

    it "takes one argument." do
      expect { sent_hearing_email_event.handle_reported_status }.to raise_error(ArgumentError)
    end

    it "does nothing if the email_sent is true." do
      sent_status_checked_at_was = sent_hearing_email_event.sent_status_checked_at
      sent_hearing_email_event.update(email_sent: true)

      sent_hearing_email_event.handle_reported_status("sent")

      expect(sent_hearing_email_event.sent_status_checked_at).to eq(sent_status_checked_at_was)
      expect(sent_hearing_email_event.email_sent).to be(true)
    end

    it "updates sent_status_checked_at if the status given is 'new'." do
      sent_status_checked_at_was = sent_hearing_email_event.sent_status_checked_at

      sent_hearing_email_event.handle_reported_status("new")

      expect(sent_hearing_email_event.sent_status_checked_at).to be > sent_status_checked_at_was
      expect(sent_hearing_email_event.email_sent).to be(nil)
      expect(sent_hearing_email_event.external_message_id).to be(nil)
    end

    it "updates sent_status_checked_at if the status given is 'sending'." do
      sent_status_checked_at_was = sent_hearing_email_event.sent_status_checked_at

      sent_hearing_email_event.handle_reported_status("sending")

      expect(sent_hearing_email_event.sent_status_checked_at).to be > sent_status_checked_at_was
      expect(sent_hearing_email_event.email_sent).to be(nil)
      expect(sent_hearing_email_event.external_message_id).to be(nil)
    end

    it "updates sent_status_checked_at and sets email_sent to true when the status is 'sent'." do
      sent_status_checked_at_was = sent_hearing_email_event.sent_status_checked_at

      sent_hearing_email_event.handle_reported_status("sent")

      expect(sent_hearing_email_event.sent_status_checked_at).to be > sent_status_checked_at_was
      expect(sent_hearing_email_event.email_sent).to be(true)
    end

    it "raises InvalidReportedStatus when an invalid status is given." do
      sent_status_checked_at_was = sent_hearing_email_event.sent_status_checked_at
      allow(Raven).to receive(:capture_exception)

      sent_hearing_email_event.handle_reported_status("bananas")

      expect(Raven).to have_received(:capture_exception).with(SentHearingEmailEvent::InvalidReportedStatus)
      expect(sent_hearing_email_event.sent_status_checked_at).to be > sent_status_checked_at_was
    end

    context "failed status" do
      SentHearingEmailEvent::FAILED_EMAIL_REPORTED_SENT_STATUSES.each do |failed_status|
        it "raises SentStatusEmailAlreadySent when #{failed_status} is given and external_message_id is present." do
          sent_status_checked_at_was = sent_hearing_email_event.sent_status_checked_at
          sent_hearing_email_event.update(external_message_id: SecureRandom.uuid)

          allow(Raven).to receive(:capture_exception)

          sent_hearing_email_event.handle_reported_status(failed_status)

          expect(Raven).to have_received(:capture_exception).with(SentHearingEmailEvent::SentStatusEmailAlreadySent)
          expect(sent_hearing_email_event.sent_status_checked_at).to be > sent_status_checked_at_was
          expect(sent_hearing_email_event.email_sent).to be(false)
        end

        it "invokes HearingEmailStatusMailer when #{failed_status} is given." do
          class HearingEmailStatusMailer
            def initialize(**args); end
            def call; end
          end

          sent_status_checked_at_was = sent_hearing_email_event.sent_status_checked_at

          allow_any_instance_of(HearingEmailStatusMailer).to receive(:call)

          sent_hearing_email_event.handle_reported_status(failed_status)

          expect_any_instance_of(HearingEmailStatusMailer).to receive(:call).once
          expect(sent_hearing_email_event.sent_status_checked_at).to be > sent_status_checked_at_was
          expect(sent_hearing_email_event.email_sent).to be(false)
        end
      end
    end
  end
end
