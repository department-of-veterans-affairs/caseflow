# frozen_string_literal: true

describe VirtualHearings::CreateConferenceJob, :all_dbs do
  context ".perform" do
    let(:hearing) { create(:hearing, regional_office: "RO06") }
    let(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }
    let(:create_job) do
      VirtualHearings::CreateConferenceJob.new(
        hearing_id: virtual_hearing.hearing_id,
        hearing_type: virtual_hearing.hearing_type
      )
    end
    let(:fake_pexip) { Fakes::PexipService.new(status_code: 400) }

    subject { create_job.perform_now }

    it "creates a conference and datadogs success", :aggregate_failures do
      subject

      virtual_hearing.reload
      expect(virtual_hearing.conference_id).to eq(9001)
      expect(virtual_hearing.status).to eq("active")
      expect(virtual_hearing.alias).to eq("0000001")
      expect(virtual_hearing.host_pin.nil?).to eq(false)
      expect(virtual_hearing.guest_pin.nil?).to eq(false)
    end

    it "sends confirmation emails if success and is processed", :aggregate_failures do
      subject

      virtual_hearing.reload
      expect(virtual_hearing.veteran_email_sent).to eq(true)
      expect(virtual_hearing.judge_email_sent).to eq(true)
      expect(virtual_hearing.representative_email_sent).to eq(true)
      expect(virtual_hearing.establishment.processed?).to eq(true)
    end

    it "logs success to datadog" do
      expect(DataDogService).to receive(:increment_counter).with(
        hash_including(
          metric_name: "created_conference.successful",
          metric_group: Constants.DATADOG_METRICS.HEARINGS.VIRTUAL_HEARINGS_GROUP_NAME,
          attrs: { hearing_id: hearing.id }
        )
      )

      subject
    end

    context "conference creation fails" do
      before do
        allow(create_job).to receive(:client).and_return(fake_pexip)
      end

      it "job goes back on queue and logs if error", :aggregate_failures do
        expect(Rails.logger).to receive(:error)

        expect { subject }.to have_enqueued_job(VirtualHearings::CreateConferenceJob)

        virtual_hearing.establishment.reload
        expect(virtual_hearing.establishment.error.nil?).to eq(false)
        expect(virtual_hearing.establishment.attempted?).to eq(true)
        expect(virtual_hearing.establishment.processed?).to eq(false)
      end

      it "logs failure to datadog" do
        expect(DataDogService).to receive(:increment_counter).with(
          hash_including(
            metric_name: "created_conference.failed",
            metric_group: Constants.DATADOG_METRICS.HEARINGS.VIRTUAL_HEARINGS_GROUP_NAME,
            attrs: { hearing_id: hearing.id }
          )
        )

        subject
      end
    end
  end
end
