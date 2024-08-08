# frozen_string_literal: true

describe ReturnLegacyAppealsToBoardJob, :all_dbs do
  describe "#perform" do
    let(:job) { described_class.new }

    it "creates a ReturnedAppealJob instance and updates its status" do
      expect do
        job.perform
      end.to change { ReturnedAppealJob.count }.by(1)

      returned_appeal_job = ReturnedAppealJob.last
      expect(returned_appeal_job.started_at).to be_present
      expect(returned_appeal_job.completed_at).to be_present
      expect(JSON.parse(returned_appeal_job.stats)["message"]).to eq("Job completed successfully")
    end

    it "sends a job report via Slack" do
      expect_any_instance_of(SlackService).to receive(:send_notification)
      job.perform
    end

    it "record runtime metrics" do
      allow(MetricsService).to receive(:record_runtime)
      expect do
        job.perform
      end.to change { ReturnedAppealJob.count }.by(1)
      expect(MetricsService).to have_received(:record_runtime).with(
        hash_including(metric_group: "return_legacy_appeals_to_board_job")
      )
    end

    context "when an error occurs" do
      let(:error_message) { "Something went wrong" }

      before do
        allow(job).to receive(:send_job_slack_report).and_raise(StandardError, error_message)
      end

      it "updates the ReturnedAppealJob with error details" do
        expect do
          job.perform
        end.to change { ReturnedAppealJob.count }.by(1)

        returned_appeal_job = ReturnedAppealJob.last
        expect(returned_appeal_job.errored_at).to be_present
        expect(JSON.parse(returned_appeal_job.stats)["message"]).to include("Job failed with error: #{error_message}")
      end

      it "sends an error notification via Slack" do
        expect_any_instance_of(SlackService).to receive(:send_notification).with(/#{error_message}/, job.class.name)
        job.perform
      end

      it "logs the error" do
        expect(job).to receive(:log_error).with(instance_of(StandardError))
        job.perform
      end
    end
  end
end
