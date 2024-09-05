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
        allow(job).to receive(:slack_report).and_return(["Job Ran Successfully, No Records Moved"])
      end

      it "sends a no records moved Slack report" do
        job.perform

        expect(job).to have_received(:send_job_slack_report).with(["Job Ran Successfully, No Records Moved"]).once
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

  describe "#create_returned_appeal_job" do
    let(:job) { described_class.new }
    context "when called" do
      it "creates a valid ReturnedAppealJob" do
        allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(2)
        returned_appeal_job = job.create_returned_appeal_job
        expect(returned_appeal_job.started_at).to be_within(1.second).of(Time.zone.now)
        expect(returned_appeal_job.stats).to eq({ message: "Job started" }.to_json)
      end
    end
  end

  describe "Slack notification" do
    let(:job) { described_class.new }
    let(:slack_service) { instance_double("SlackService") }

    before do
      allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(2)
      allow(job).to receive(:slack_service).and_return(slack_service)
      job.instance_variable_set(
        :@filtered_appeals, {
          priority_appeals_count: 5,
          non_priority_appeals_count: 3,
          remaining_priority_appeals_count: 10,
          remaining_non_priority_appeals_count: 7,
          grouped_by_avlj: %w[AVJL1 AVJL2]
        }
      )
    end

    describe "#slack_report" do
      it "slack_report has an array" do
        expected_report = [
          "Job performed successfully",
          "Total Priority Appeals Moved: 5",
          "Total Non-Priority Appeals Moved: 3",
          "Total Remaining Priority Appeals: 10",
          "Total Remaining Non-Priority Appeals: 7",
          "SATTYIDs of Non-SSC AVLJs Moved: AVJL1, AVJL2"
        ]

        expect(job.slack_report).to eq(expected_report)
      end
    end

    describe "#send_job_slack_report" do
      context "when slack_report has messages" do
        it "sends a notification to Slack with the correct message" do
          slack_message = job.slack_report
          expected_message = slack_message.join("\n")

          expect(slack_service).to receive(:send_notification).with(expected_message, job.class.name)

          job.send_job_slack_report(slack_message)
        end
      end
    end
  end

  describe "#get_tied_appeal_bfkeys" do
    let(:job) { described_class.new }
    let(:appeal_1) { { "priority" => 0, "bfd19" => 10.days.ago, "bfkey" => "1" } }
    let(:appeal_2) { { "priority" => 1, "bfd19" => 8.days.ago, "bfkey" => "2" } }
    let(:appeal_3) { { "priority" => 0, "bfd19" => 6.days.ago, "bfkey" => "3" } }
    let(:appeal_4) { { "priority" => 1, "bfd19" => 4.days.ago, "bfkey" => "4" } }

    context "with a mix of priority and non-priority appeals" do
      let(:tied_appeals) { [appeal_1, appeal_2, appeal_3, appeal_4] }

      it "returns the keys sorted by priority and then bfd19" do
        allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(2)
        result = job.get_tied_appeal_bfkeys(tied_appeals)
        expect(result).to eq(%w[2 4 1 3])
      end
    end
  end
end
