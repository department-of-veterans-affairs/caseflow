# frozen_string_literal: true

describe VirtualHearings::SendReminderEmailsJob do
  let(:hearing_date) { Time.zone.now }
  let(:ama_disposition) { nil }
  let(:hearing_day) do
    create(
      :hearing_day,
      regional_office: "RO42",
      scheduled_for: hearing_date,
      request_type: HearingDay::REQUEST_TYPES[:virtual]
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
  let(:appellant_reminder_sent) { nil }
  let(:representative_email) { "representative@test.gov" }
  let(:representative_reminder_sent) { nil }
  let!(:virtual_hearing) do
    create(
      :virtual_hearing,
      :initialized,
      status: :active,
      appellant_email: appellant_email,
      appellant_reminder_sent: appellant_reminder_sent,
      representative_email: representative_email,
      representative_reminder_sent: representative_reminder_sent,
      hearing: hearing
    )
  end

  describe "#perform" do
    subject { VirtualHearings::SendReminderEmailsJob.new.perform }

    context "hearing date is 7 days out", :aggregate_failures do
      let(:hearing_date) { Time.zone.now + 7.days }

      it "sends reminder emails" do
        expect(VirtualHearingMailer).to receive(:reminder).twice.and_call_original

        subject
        virtual_hearing.reload
        expect(virtual_hearing.appellant_reminder_sent).not_to be_nil
        expect(virtual_hearing.representative_reminder_sent).not_to be_nil
      end

      it "creates sent email events" do
        subject

        expect(SentHearingEmailEvent.count).to eq(2)
        expect(SentHearingEmailEvent.is_reminder.count).to eq(2)
      end

      context "representative email was already sent" do
        let(:representative_reminder_sent) { hearing_date - 3.days }

        it "sends reminder email for the appellant" do
          expect(VirtualHearingMailer).to receive(:reminder).once.and_call_original

          subject
          virtual_hearing.reload
          expect(virtual_hearing.appellant_reminder_sent).not_to be_nil
          expect(virtual_hearing.representative_reminder_sent).to(
            be_within(1.second).of(representative_reminder_sent)
          )
        end
      end

      context "appellant email was already sent" do
        let(:appellant_reminder_sent) { hearing_date - 4.days }

        it "sends reminder email for the representative" do
          expect(VirtualHearingMailer).to receive(:reminder).once.and_call_original

          subject
          virtual_hearing.reload
          expect(virtual_hearing.appellant_reminder_sent).to(
            be_within(1.second).of(appellant_reminder_sent)
          )
          expect(virtual_hearing.representative_reminder_sent).not_to be_nil
        end
      end

      context "representative email is nil" do
        let(:representative_email) { nil }

        it "sends reminder email to the appellant only" do
          expect(VirtualHearingMailer).to receive(:reminder).once.and_call_original

          subject
          virtual_hearing.reload
          expect(virtual_hearing.appellant_reminder_sent).not_to be_nil
          expect(virtual_hearing.representative_reminder_sent).to be_nil
        end
      end
    end
  end
end
