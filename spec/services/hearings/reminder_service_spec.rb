# frozen_string_literal: true

describe Hearings::ReminderService do
  shared_examples "determines which reminders should send" do
    context "hearing date is 7 days out" do
      let(:hearing_date) { Time.zone.now + 6.days } # Nov 5, 2020 12:00 UTC + 6.days => 7 days or less
      let(:created_at) { hearing_date - 8.days }

      context "last_sent_reminder is nil" do
        let(:last_sent_reminder) { nil }

        it "returns true" do
          expect(subject).to eq(true)
        end
      end

      context "last_sent_reminder is 5 days out" do
        let(:last_sent_reminder) { hearing_date - 5.days }

        it "returns false" do
          expect(subject).to eq(false)
        end
      end
    end

    context "hearing date is 5 days out" do
      let(:hearing_date) { Time.zone.now + 5.days }

      context "created_at is 6 days from the hearing date" do
        let(:created_at) { hearing_date - 6.days }

        context "last_sent_reminder is nil" do
          let(:last_sent_reminder) { nil }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end
    end

    context "hearing date is 2 days out" do
      let(:hearing_date) { Time.zone.now + 1.day } # Nov 5, 2020 12:00 UTC + 1.day => 2 days or less
      let(:created_at) { hearing_date - 3.days }

      context "last_sent_reminder is nil" do
        let(:last_sent_reminder) { nil }

        it "returns true" do
          expect(subject).to eq(true)
        end
      end

      context "last_sent_reminder is 4 days out" do
        let(:last_sent_reminder) { hearing_date - 4.days }
        let(:created_at) { hearing_date - 5.days }

        it "returns true" do
          expect(subject).to eq(true)
        end
      end

      context "last_sent_reminder is 1 days out" do
        let(:last_sent_reminder) { hearing_date - 1.day }
        let(:created_at) { hearing_date - 2.days }

        it "returns false" do
          expect(subject).to eq(false)
        end
      end
    end

    context "hearing date is 1 day out" do
      let(:hearing_date) { Time.zone.now + 10.hours } # Nov 5, 2020 12:00 UTC + 10.hours => 1 day or less

      context "created_at is 1.5 days from the hearing date" do
        let(:created_at) { hearing_date - 1.day - 12.hours }

        context "last_sent_reminder is nil" do
          let(:last_sent_reminder) { nil }

          it "returns false" do
            expect(subject).to eq(false)
          end
        end
      end
    end

    context "hearing date is 3 days out" do
      let(:created_at) { hearing_date - 4.days }

      context "hearing date is on a monday" do
        let(:hearing_date) { Time.utc(2020, 11, 9, 12, 0, 0) } # Nov 9, 2020(Monday)

        context "last_sent_reminder is 4 days out" do
          let(:last_sent_reminder) { hearing_date - 4.days }

          context "today is friday" do
            before do
              Timecop.freeze(Time.utc(2020, 11, 6, 13, 30, 0)) # Nov 6, 2020 13:30:00 UTC(Friday)
            end

            it "returns true" do
              expect(subject).to eq(true)
            end
          end

          context "today is thursday" do
            it "returns false" do
              expect(subject).to eq(false)
            end
          end
        end
      end

      context "hearing date is on a tuesday" do
        let(:hearing_date) { Time.utc(2020, 11, 10, 12, 0, 0) } # Nov 10, 2020 (Tuesday)

        context "last_sent_reminder is 4 days out" do
          let(:last_sent_reminder) { hearing_date - 4.days }

          context "today is saturday" do
            before do
              Timecop.freeze(Time.utc(2020, 11, 7, 12, 0, 0)) # Nov 7, 2020 (Saturday)
            end

            it "returns false" do
              expect(subject).to eq(false)
            end
          end
        end
      end
    end
  end

  context "with a virtual hearing" do
    let(:hearing_day) { create(:hearing_day, scheduled_for: hearing_date) }
    let(:hearing) { create(:hearing, hearing_day: hearing_day) } # scheduled_time is always 8:30 AM ET
    let(:virtual_hearing) do
      create(
        :virtual_hearing,
        :initialized,
        status: :active,
        hearing: hearing,
        created_at: created_at
      )
    end

    before do
      Timecop.freeze(Time.utc(2020, 11, 5, 12, 0, 0)) # Nov 5, 2020 12:00 ET (Thursday)
      hearing
      virtual_hearing
      hearing.reload
    end

    after { Timecop.return }

    context ".should_send_reminder_email?" do
      subject do
        described_class.new(
          hearing: hearing,
          last_sent_reminder: last_sent_reminder,
          created_at: created_at
        ).should_send_reminder_email?
      end
      include_examples "determines which reminders should send"
    end
  end

  # Right now these tests will fail because we don't send emails for non-virtual
  # hearings. Once we are sending emails, uncomment this and it should pass.
  # See: send_reminder_emails_job_spec as well.
  # context "with no virtual hearing" do
  #  let(:hearing_day) { create(:hearing_day, scheduled_for: hearing_date) }
  #  let(:hearing) do
  #    create(:hearing, hearing_day: hearing_day, created_at: created_at) } # scheduled_time is always 8:30 AM ET
  #  end
  #
  #  before do
  #    Timecop.freeze(Time.utc(2020, 11, 5, 12, 0, 0)) # Nov 5, 2020 12:00 ET (Thursday)
  #    hearing
  #    hearing.reload
  #  end
  #
  #  after { Timecop.return }
  #
  #    context ".should_send_reminder_email?" do
  #    subject do
  #      described_class.new(
  #        hearing: hearing,
  #        last_sent_reminder: last_sent_reminder,
  #        created_at: created_at
  #      ).should_send_reminder_email?
  #    end
  #    include_examples "determines which reminders should send"
  #  end
  # end
end
