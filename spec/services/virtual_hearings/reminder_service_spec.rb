# frozen_string_literal: true

describe VirtualHearings::ReminderService do
  let(:hearing_day) { build(:hearing_day, scheduled_for: hearing_date) }
  let(:hearing) { build(:hearing, hearing_day: hearing_day) }
  let!(:virtual_hearing) do
    build(
      :virtual_hearing,
      :initialized,
      status: :active,
      hearing: hearing
    )
  end

  context ".should_send_reminder_email?" do
    subject do
      described_class.new(virtual_hearing, last_sent_reminder).should_send_reminder_email?
    end

    context "hearing date is 7 days out" do
      let(:hearing_date) { Time.zone.now + 7.days }

      context "last_sent_reminder is nil" do
        let(:last_sent_reminder) { nil }

        it "returns true" do
          expect(subject).to eq(true)
        end
      end

      context "last_sent_reminder was send 5 days out" do
        let(:last_sent_reminder) { Time.zone.now + 5.days }

        it "returns false" do
          expect(subject).to eq(false)
        end
      end
    end
  end
end
