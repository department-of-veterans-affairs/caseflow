# frozen_string_literal: true

describe HearingUpdateForm, :all_dbs do
  describe ".update" do
    let!(:user) { create(:user) }
    let(:nyc_ro_eastern) { "RO06" }
    let(:video_type) { HearingDay::REQUEST_TYPES[:video] }
    let(:hearing_day) { create(:hearing_day, regional_office: nyc_ro_eastern, request_type: video_type) }
    let!(:hearing) { create(:hearing, hearing_day: hearing_day) }
    let(:params) do
      {
        hearing: hearing.reload,
        virtual_hearing_attributes: {
          veteran_email: "veteran@example.com",
          representative_email: "representative@example.com"
        }
      }
    end
    let(:create_conference_job) { double(VirtualHearings::CreateConferenceJob) }

    before do
      RequestStore[:current_user] = user

      # mock CreateConferenceJob so its datadog calls don't interfere with our tests
      allow(VirtualHearings::CreateConferenceJob).to receive(:new).and_return(create_conference_job)
      allow(create_conference_job).to receive(:perform_now) # and do nothing
    end

    subject { HearingUpdateForm.new(params) }

    context "updating a virtual hearing" do
      context "that is initialized and all emails have been sent" do
        let!(:virtual_hearing) do
          create(
            :virtual_hearing,
            :initialized,
            :all_emails_sent,
            status: :active,
            hearing: hearing
          )
        end

        it "sends an update event to datadog" do
          expect(DataDogService).to receive(:increment_counter).with(
            hash_including(
              metric_name: "updated_virtual_hearing.successful",
              metric_group: Constants.DATADOG_METRICS.HEARINGS.VIRTUAL_HEARINGS_GROUP_NAME,
              attrs: { hearing_id: hearing.id }
            )
          )
          subject.update
        end
      end

      context "that is initialized, but emails were not all sent" do
        let!(:virtual_hearing) do
          create(
            :virtual_hearing,
            :initialized,
            status: :active,
            hearing: hearing
          )
        end

        it "returns an alert error", :aggregate_failures do
          form = subject
          form.update

          expect(form.hearing_alerts.size).to be(1)
          expect(form.hearing_alerts.detect { |alert| alert.type == "error" }).not_to be_nil
        end
      end
    end

    context "creating a virtual hearing" do
      it "sends a create event to datadog" do
        expect(DataDogService).to receive(:increment_counter).with(
          hash_including(
            metric_name: "created_virtual_hearing.successful",
            metric_group: Constants.DATADOG_METRICS.HEARINGS.VIRTUAL_HEARINGS_GROUP_NAME,
            attrs: { hearing_id: hearing.id }
          )
        )
        subject.update
      end
    end
  end
end
