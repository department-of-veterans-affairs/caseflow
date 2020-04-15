# frozen_string_literal: true

describe VirtualHearings::DeleteConferencesJob do
  context "#perform" do
    let(:job) { VirtualHearings::DeleteConferencesJob.new }

    subject { job.perform_now }

    let(:scheduled_for) { Time.zone.now - 1.day }
    let(:hearing_day) do
      create(
        :hearing_day,
        regional_office: "RO42",
        request_type: "V",
        judge: create(:user, :judge),
        scheduled_for: Time.zone.now - 1.day
      )
    end
    let(:hearing) { create(:hearing, regional_office: "RO42", hearing_day: hearing_day) }

    context "for virtual hearing that has already been cleaned up" do
      let!(:virtual_hearing) do
        create(
          :virtual_hearing,
          hearing: hearing,
          conference_deleted: true,
          veteran_email_sent: true,
          representative_email_sent: true,
          judge_email_sent: true
        )
      end

      it "runs but does nothing" do
        expect(job).not_to receive(:delete_conference)
        subject
      end
    end

    context "for virtual hearing that was cancelled" do
      let(:scheduled_for) { Time.zone.now + 7.days }
      let!(:virtual_hearing) do
        create(:virtual_hearing, status: :cancelled, hearing: hearing, conference_deleted: false)
      end

      it "updates the appropriate fields", :aggregate_failures do
        subject
        virtual_hearing.reload
        expect(virtual_hearing.conference_deleted).to eq(true)
        expect(virtual_hearing.veteran_email_sent).to eq(true)
        expect(virtual_hearing.representative_email_sent).to eq(true)
        expect(virtual_hearing.judge_email_sent).to eq(false) # judge should not receive cancellation email
      end
    end

    context "for a virtual hearing that was cancelled, but the emails failed to send" do
      let!(:virtual_hearing) do
        create(:virtual_hearing, status: :cancelled, hearing: hearing, conference_deleted: true)
      end

      it "doesn't call `delete_conference` and sends each email" do
        subject
        virtual_hearing.reload
        expect(job).to_not receive(:delete_conference)
        expect(virtual_hearing.veteran_email_sent).to eq(true)
        expect(virtual_hearing.representative_email_sent).to eq(true)
        expect(virtual_hearing.judge_email_sent).to eq(false) # judge should not receive cancellation email
      end
    end

    context "for virtual hearing that already occurred" do
      let(:scheduled_for) { Time.zone.now - 7.days }
      let!(:virtual_hearing) do
        create(:virtual_hearing, status: :active, hearing: hearing, conference_deleted: false)
      end

      it "updates the conference_deleted, but doesn't send emails", :aggregate_failures do
        subject
        virtual_hearing.reload
        expect(virtual_hearing.conference_deleted).to eq(true)
        expect(virtual_hearing.veteran_email_sent).to eq(false)
        expect(virtual_hearing.representative_email_sent).to eq(false)
        expect(virtual_hearing.judge_email_sent).to eq(false)
      end
    end

    context "for multiple virtual hearings" do
      let!(:virtual_hearings) do
        [
          create(
            :virtual_hearing,
            :initialized,
            status: :active,
            hearing: create(:hearing, hearing_day: hearing_day),
            conference_deleted: false
          ),
          create(
            :virtual_hearing,
            :initialized,
            status: :active,
            hearing: create(:hearing, hearing_day: hearing_day),
            conference_deleted: false
          )
        ]
      end

      it "it marks the virtual hearing as deleted" do
        expect(job).to receive(:client).twice.and_return(PexipService.new)
        expect(DataDogService).to receive(:increment_counter).with(
          hash_including(
            metric_name: "deleted_conferences.successful",
            metric_group: Constants.DATADOG_METRICS.HEARINGS.VIRTUAL_HEARINGS_GROUP_NAME,
            by: 2
          )
        )
        subject
        virtual_hearings.each(&:reload)
        expect(virtual_hearings.map(&:conference_deleted)).to all(be == true)
      end

      context "pexip returns an error" do
        it "does not mark the virtual hearings as deleted" do
          fake_service = PexipService.new(status_code: 400)
          expect(job).to receive(:client).twice.and_return(fake_service)
          expect(DataDogService).to receive(:increment_counter).with(
            hash_including(
              metric_name: "deleted_conferences.failed",
              metric_group: Constants.DATADOG_METRICS.HEARINGS.VIRTUAL_HEARINGS_GROUP_NAME,
              by: 2
            )
          )
          subject
          virtual_hearings.each(&:reload)
          expect(virtual_hearings.map(&:conference_deleted)).to all(be == false)
        end

        it "assumes a 404 means the virtual hearing conference was already deleted" do
          fake_service = PexipService.new(status_code: 404)
          expect(job).to receive(:client).twice.and_return(fake_service)
          expect(DataDogService).to receive(:increment_counter).with(
            hash_including(
              metric_name: "deleted_conferences.successful",
              metric_group: Constants.DATADOG_METRICS.HEARINGS.VIRTUAL_HEARINGS_GROUP_NAME,
              by: 2
            )
          )
          subject
          virtual_hearings.each(&:reload)
          expect(virtual_hearings.map(&:conference_deleted)).to all(be == true)
        end
      end
    end
  end
end
