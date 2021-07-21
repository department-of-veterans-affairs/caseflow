# frozen_string_literal: true

describe Hearings::SendReminderEmailsJob do
  let(:hearing_date) { Time.zone.now }
  let(:ama_disposition) { nil }
  let(:hearing_day) do
    create(
      :hearing_day,
      :virtual,
      scheduled_for: hearing_date
    )
  end
  let(:hearing) do
    create(
      :hearing,
      hearing_day: hearing_day,
      disposition: ama_disposition
    )
  end
  let(:appellant_email) { "appellant@test.gov" }
  let(:appellant_reminder_sent_at) { nil }
  let(:representative_email) { "representative@test.gov" }
  let(:representative_reminder_sent_at) { nil }
  let!(:virtual_hearing) do
    create(
      :virtual_hearing,
      :initialized,
      status: :active,
      appellant_email: appellant_email,
      appellant_reminder_sent_at: appellant_reminder_sent_at,
      representative_email: representative_email,
      representative_reminder_sent_at: representative_reminder_sent_at,
      hearing: hearing,
      created_at: Time.zone.now - 14.days
    )
  end

  describe "#perform" do
    subject { Hearings::SendReminderEmailsJob.new.perform }

    context "hearing date is 7 days out" do
      let(:hearing_date) { Time.zone.now + 6.days } # at most 7 days out

      it "sends reminder emails", :aggregate_failures do
        expect(HearingMailer).to receive(:reminder).twice.and_call_original

        subject
        virtual_hearing.reload
        expect(virtual_hearing.appellant_reminder_sent_at).not_to be_nil
        expect(virtual_hearing.representative_reminder_sent_at).not_to be_nil
      end

      it "creates sent email events", :aggregate_failures do
        subject

        expect(SentHearingEmailEvent.count).to eq(2)
        expect(SentHearingEmailEvent.is_reminder.count).to eq(2)
        expect(SentHearingEmailEvent.is_reminder.map(&:sent_by)).to all(eq(User.system_user))
      end

      context "representative email was already sent" do
        let(:representative_reminder_sent_at) { hearing_date - 3.days }
        let!(:representative_reminder) do
          create(
            :sent_hearing_email_event,
            :reminder,
            sent_at: representative_reminder_sent_at,
            email_recipient: hearing.representative_recipient
          )
        end

        it "sends reminder email for the appellant", :aggregate_failures do
          expect(HearingMailer).to receive(:reminder).once.and_call_original

          subject
          virtual_hearing.reload
          expect(virtual_hearing.appellant_reminder_sent_at).not_to be_nil
          expect(virtual_hearing.representative_reminder_sent_at).to(
            be_within(1.second).of(representative_reminder_sent_at)
          )
        end
      end

      context "appellant email was already sent" do
        let(:appellant_reminder_sent_at) { hearing_date - 4.days }
        let!(:appellant_reminder) do
          create(
            :sent_hearing_email_event,
            :reminder,
            sent_at: appellant_reminder_sent_at,
            email_recipient: hearing.appellant_recipient
          )
        end

        it "sends reminder email for the representative", :aggregate_failures do
          expect(HearingMailer).to receive(:reminder).once.and_call_original

          subject
          virtual_hearing.reload
          expect(virtual_hearing.appellant_reminder_sent_at).to(
            be_within(1.second).of(appellant_reminder_sent_at)
          )
          expect(virtual_hearing.representative_reminder_sent_at).not_to be_nil
        end
      end

      context "representative email is nil" do
        let(:representative_email) { nil }

        it "sends reminder email to the appellant only", :aggregate_failures do
          expect(HearingMailer).to receive(:reminder).once.and_call_original

          subject
          virtual_hearing.reload
          expect(virtual_hearing.appellant_reminder_sent_at).not_to be_nil
          expect(virtual_hearing.representative_reminder_sent_at).to be_nil
        end
      end

      it "doesn't double send the email", :aggregate_failures do
        expect(HearingMailer).to receive(:reminder).twice.and_call_original

        subject # First Send

        virtual_hearing.reload
        expect(virtual_hearing.appellant_reminder_sent_at).not_to be_nil
        expect(virtual_hearing.representative_reminder_sent_at).not_to be_nil

        appellant_reminder_sent_at = virtual_hearing.appellant_reminder_sent_at
        representative_reminder_sent_at = virtual_hearing.representative_reminder_sent_at

        Timecop.travel(Time.zone.now + 10.hours)

        Hearings::SendReminderEmailsJob.new.perform # Second Send (subject is memoized)

        virtual_hearing.reload
        expect(virtual_hearing.appellant_reminder_sent_at).to eq(appellant_reminder_sent_at)
        expect(virtual_hearing.representative_reminder_sent_at).to eq(representative_reminder_sent_at)
      end
    end

    context "hearing date is 2 days out" do
      let(:hearing_date) { Time.zone.now + 1.day } # at most 2 days out

      context "sent reminder emails 5 days out" do
        let(:appellant_reminder_sent_at) { hearing_date - 4.days }
        let!(:appellant_reminder) do
          create(
            :sent_hearing_email_event,
            :reminder,
            sent_at: appellant_reminder_sent_at,
            email_recipient: hearing.appellant_recipient
          )
        end
        let(:representative_reminder_sent_at) { hearing_date - 4.days }
        let!(:representative_reminder) do
          create(
            :sent_hearing_email_event,
            :reminder,
            sent_at: representative_reminder_sent_at,
            email_recipient: hearing.representative_recipient
          )
        end

        it "sends reminder emails", :aggregate_failures do
          expect(HearingMailer).to receive(:reminder).twice.and_call_original

          subject
          virtual_hearing.reload
          # Expect appellant_reminder_sent_at and representative_reminder_sent_at to change
          # from the value we setup because the emails were sent.
          expect(virtual_hearing.appellant_reminder_sent_at).not_to(
            be_within(1.second).of(representative_reminder_sent_at)
          )
          expect(virtual_hearing.representative_reminder_sent_at).not_to(
            be_within(1.second).of(representative_reminder_sent_at)
          )
        end
      end
    end

    context "hearing date is 1 day out" do
      before do
        Timecop.freeze(Time.utc(2020, 11, 5, 12, 0, 0)) # Nov 5, 2020 12:00 ET (Thursday)
      end

      let(:hearing_date) { Time.zone.now + 10.hours } #  Nov 5, 2020 12:00 ET + 10 hours

      context "sent reminder emails 2 days out" do

        let(:appellant_reminder_sent_at) { hearing_date - 2.days }
        let!(:appellant_reminder) do
          create(
            :sent_hearing_email_event,
            :reminder,
            sent_at: appellant_reminder_sent_at,
            email_recipient: hearing.appellant_recipient
          )
        end
        let(:representative_reminder_sent_at) { hearing_date - 2.days }
        let!(:representative_reminder) do
          create(
            :sent_hearing_email_event,
            :reminder,
            sent_at: representative_reminder_sent_at,
            email_recipient: hearing.representative_recipient
          )
        end

        it "does not send reminder emails", :aggregate_failures do
          expect(HearingMailer).not_to receive(:reminder)

          subject
          virtual_hearing.reload
          # Expect appellant_reminder_sent_at and representative_reminder_sent_at to remain
          # the same as the times we setup because the emails weren't sent.
          expect(virtual_hearing.appellant_reminder_sent_at).to(
            be_within(1.second).of(appellant_reminder_sent_at)
          )
          expect(virtual_hearing.representative_reminder_sent_at).to(
            be_within(1.second).of(representative_reminder_sent_at)
          )
        end
      end
    end

    context "Encountered error" do
      let(:hearing_date) { Time.zone.now + 6.days } # at most 7 days out

      before do
        allow_any_instance_of(Hearings::SendEmail)
          .to receive(:send_email)
          .and_raise(Hearings::SendEmail::RecipientIsDeceasedVeteran)
      end

      it "captures error and continues without failing" do
        expect(Raven).to receive(:capture_exception)
          .with(Hearings::SendEmail::RecipientIsDeceasedVeteran, any_args)

        subject
      end
    end
  end
end
