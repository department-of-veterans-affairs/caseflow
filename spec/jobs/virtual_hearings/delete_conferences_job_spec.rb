# frozen_string_literal: true

describe VirtualHearings::DeleteConferencesJob do
  context "#perform" do
    shared_examples "sends emails to veteran and representative" do
      it "updates the appropriate fields", :aggregate_failures do
        subject
        virtual_hearing.reload
        expect(virtual_hearing.conference_deleted).to eq(true)
        expect(virtual_hearing.veteran_email_sent).to eq(true)
        expect(virtual_hearing.representative_email_sent).to eq(true)
        expect(virtual_hearing.judge_email_sent).to eq(false) # judge should not receive cancellation email
      end

      it "creates events for emails sent", :aggregate_failures do
        subject
        virtual_hearing.reload
        events = SentHearingEmailEvent.where(hearing_id: hearing.id)
        expect(events.count).to eq 2
        expect(events.where(sent_by_id: virtual_hearing.updated_by_id).count).to eq 2
        expect(events.where(email_type: "cancellation").count).to eq 2
        expect(events.where(email_address: virtual_hearing.veteran_email).count).to eq 1
        expect(events.where(recipient_role: "veteran").count).to eq 1
        expect(events.where(email_address: virtual_hearing.representative_email).count).to eq 1
        expect(events.where(recipient_role: "representative").count).to eq 1
        expect(events.where(recipient_role: "judge").count).to eq 0
      end
    end

    shared_examples "doesn't create email events" do
      it "doesn't create send email events" do
        subject
        expect(hearing.email_events.count).to eq(0)
      end
    end

    shared_examples "doesn't send any emails" do
      it "updates the conference_deleted, but doesn't send emails", :aggregate_failures do
        subject
        virtual_hearing.reload
        expect(virtual_hearing.conference_deleted).to eq(true)
        expect(virtual_hearing.veteran_email_sent).to eq(false)
        expect(virtual_hearing.representative_email_sent).to eq(false)
        expect(virtual_hearing.judge_email_sent).to eq(false)
      end

      include_examples "doesn't create email events"
    end

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
        expect(hearing.email_events.count).to eq(0)
        subject
      end
    end

    context "for virtual hearing that was cancelled" do
      let(:scheduled_for) { Time.zone.now + 7.days }
      let!(:virtual_hearing) do
        create(:virtual_hearing, status: :cancelled, hearing: hearing, conference_deleted: false)
      end

      include_examples "sends emails to veteran and representative"
    end

    context "for a cancelled virtual hearing that was cleaned up, but the emails failed to send initially" do
      let!(:virtual_hearing) do
        create(:virtual_hearing, status: :cancelled, hearing: hearing, conference_deleted: true)
      end

      include_examples "sends emails to veteran and representative"
    end

    context "for virtual hearing that already occurred" do
      let(:scheduled_for) { Time.zone.now - 7.days }
      let!(:virtual_hearing) do
        create(:virtual_hearing, status: :active, hearing: hearing, conference_deleted: false)
      end

      include_examples "doesn't send any emails"
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

      context "pexip returns a 400" do
        before do
          fake_service = PexipService.new(status_code: 400)
          expect(job).to receive(:client).twice.and_return(fake_service)
        end

        it "does not mark the virtual hearings as deleted" do
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

        include_examples "doesn't create email events"
      end

      context "pexip returns a 404" do
        before do
          fake_service = PexipService.new(status_code: 404)
          expect(job).to receive(:client).twice.and_return(fake_service)
        end

        it "assumes a 404 means the virtual hearing conference was already deleted" do
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

        # Virtual hearings are not cancelled, so no emails get sent.
        include_examples "doesn't create email events"
      end
    end
  end
end
