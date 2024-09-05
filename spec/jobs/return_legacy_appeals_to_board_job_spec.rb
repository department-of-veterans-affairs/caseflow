# frozen_string_literal: true

describe ReturnLegacyAppealsToBoardJob, :all_dbs do
  describe "#perform" do
    let(:job) { described_class.new }
    let(:returned_appeal_job) { instance_double("ReturnedAppealJob", id: 1) }
    let(:appeals) { [{ "bfkey" => "1", "priority" => 1 }, { "bfkey" => "2", "priority" => 0 }] }
    let(:moved_appeals) { [{ "bfkey" => "1", "priority" => 1 }] }

    before do
      allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(2)

      allow(job).to receive(:create_returned_appeal_job).and_return(returned_appeal_job)
      allow(returned_appeal_job).to receive(:update!)
      allow(job).to receive(:eligible_and_moved_appeals).and_return([appeals, moved_appeals])
      allow(job).to receive(:filter_appeals).and_return({})
      allow(job).to receive(:send_job_slack_report)
      allow(job).to receive(:complete_returned_appeal_job)
      allow(job).to receive(:metrics_service_report_runtime)
    end

    context "when the job completes successfully" do
      it "creates a ReturnedAppealJob instance, processes appeals, and sends a report" do
        allow(job).to receive(:slack_report).and_return(["Job completed successfully"])

        job.perform

        expect(job).to have_received(:create_returned_appeal_job).once
        expect(job).to have_received(:eligible_and_moved_appeals).once
        expect(job).to have_received(:complete_returned_appeal_job)
          .with(returned_appeal_job, "Job completed successfully", moved_appeals).once
        expect(job).to have_received(:send_job_slack_report).with(["Job completed successfully"]).once
        expect(job).to have_received(:metrics_service_report_runtime)
          .with(metric_group_name: "return_legacy_appeals_to_board_job").once
      end
    end

    context "when no appeals are moved" do
      before do
        allow(job).to receive(:eligible_and_moved_appeals).and_return([appeals, nil])
        allow(job).to receive(:complete_returned_appeal_job)
      end

      it "sends a no records moved Slack report and completes the job" do
        job.perform

        expect(job).to have_received(:send_job_slack_report).with(described_class::NO_RECORDS_FOUND_MESSAGE).once
        expect(job).to have_received(:complete_returned_appeal_job)
          .with(returned_appeal_job, Constants.DISTRIBUTION.no_records_moved_message, []).once
        expect(job).to have_received(:metrics_service_report_runtime).once
      end
    end

    context "when an error occurs" do
      let(:error_message) { "Unexpected error" }
      let(:slack_service_instance) { instance_double(SlackService) }

      before do
        allow(job).to receive(:eligible_and_moved_appeals).and_raise(StandardError, error_message)
        allow(job).to receive(:log_error)
        allow(returned_appeal_job).to receive(:update!)
        allow(SlackService).to receive(:new).and_return(slack_service_instance)
        allow(slack_service_instance).to receive(:send_notification)
      end

      it "handles the error, logs it, and sends a Slack notification" do
        job.perform

        expect(job).to have_received(:log_error).with(instance_of(StandardError))
        expect(returned_appeal_job).to have_received(:update!)
          .with(hash_including(errored_at: kind_of(Time),
                               stats: "{\"message\":\"Job failed with error: #{error_message}\"}")).once
        expect(slack_service_instance).to have_received(:send_notification).with(
          a_string_matching(/<!here>\n \[ERROR\]/), job.class.name
        ).once
        expect(job).to have_received(:metrics_service_report_runtime).once
      end
    end
  end
end
