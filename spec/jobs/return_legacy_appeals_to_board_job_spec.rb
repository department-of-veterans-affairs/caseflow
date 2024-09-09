# frozen_string_literal: true

describe ReturnLegacyAppealsToBoardJob, :all_dbs do
  let(:job) { described_class.new }
  let(:nonsscavlj_number_of_appeals_to_move_count) { 2 }

  before do
    allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move)
      .and_return(nonsscavlj_number_of_appeals_to_move_count)
  end

  describe "#perform" do
    let(:returned_appeal_job) { instance_double("ReturnedAppealJob", id: 1) }
    let(:appeals) { [{ "bfkey" => "1", "priority" => 1 }, { "bfkey" => "2", "priority" => 0 }] }
    let(:moved_appeals) { [{ "bfkey" => "1", "priority" => 1 }] }

    before do
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

  describe "#non_ssc_avljs" do
    context "2 non ssc avljs exist" do
      let!(:non_ssc_avlj_user_1) { create(:user, :non_ssc_avlj_user) }
      let!(:non_ssc_avlj_user_2) { create(:user, :non_ssc_avlj_user) }
      let!(:ssc_avlj_user) { create(:user, :ssc_avlj_user) }

      it "returns both non ssc avljs" do
        expect(job.send(:non_ssc_avljs)).to eq([non_ssc_avlj_user_1.vacols_staff, non_ssc_avlj_user_2.vacols_staff])
      end
    end

    context "1 each of non ssc avlj, ssc avlj, regular vlj, inactive non ssc avlj exist" do
      let!(:non_ssc_avlj_user) { create(:user, :non_ssc_avlj_user) }
      let!(:inactive_non_ssc_avlj_user) { create(:user, :inactive, :non_ssc_avlj_user) }
      let!(:ssc_avlj_user) { create(:user, :ssc_avlj_user) }
      let!(:user) { create(:user, :with_vacols_record) }

      before do
        inactive_non_ssc_avlj_user.vacols_staff.update!(sactive: "I")
      end

      it "returns only the non ssc avlj" do
        expect(job.send(:non_ssc_avljs)).to eq([non_ssc_avlj_user.vacols_staff])
      end
    end

    context "no non ssc avljs exist" do
      let!(:ssc_avlj_user) { create(:user, :ssc_avlj_user) }

      it "returns an empty array" do
        expect(job.send(:non_ssc_avljs)).to eq([])
      end
    end
  end

  describe "#update_qualifying_appeals_bfkeys" do
    context "maximum moved appeals per non ssc avlj is 2 and a starting bfkey list of 2 and a tied list of 4 keys" do
      let(:tied_appeals_bfkeys) { %w[3 4 5 6] }
      let(:qualifying_appeals_bfkeys) { %w[1 2] }

      it "adds 2 keys to qualifying bfkey list" do
        appeals = job.send(:update_qualifying_appeals_bfkeys, tied_appeals_bfkeys, qualifying_appeals_bfkeys)

        expect(appeals).to eq(%w[1 2 3 4])
      end
    end

    context "maximum moved appeals per non ssc avlj is 4 and a starting bfkey list of 2 and a tied list of 4 keys" do
      let(:nonsscavlj_number_of_appeals_to_move_count) { 4 }
      let(:tied_appeals_bfkeys) { %w[3 4 5 6] }
      let(:qualifying_appeals_bfkeys) { %w[1 2] }

      it "adds all tied keys to qualifying bfkey list" do
        appeals = job.send(:update_qualifying_appeals_bfkeys, tied_appeals_bfkeys, qualifying_appeals_bfkeys)

        expect(appeals).to eq(%w[1 2 3 4 5 6])
      end
    end

    context "maximum moved appeals per non ssc avlj is higher than the length of the tied list and a starting bfkey "\
      "list of 2 and a tied list of 4 keys" do
      let(:nonsscavlj_number_of_appeals_to_move_count) { 10 }
      let(:tied_appeals_bfkeys) { %w[3 4 5 6] }
      let(:qualifying_appeals_bfkeys) { %w[1 2] }

      it "adds all tied keys to qualifying bfkey list" do
        appeals = job.send(:update_qualifying_appeals_bfkeys, tied_appeals_bfkeys, qualifying_appeals_bfkeys)

        expect(appeals).to eq(%w[1 2 3 4 5 6])
      end
    end

    context "maximum moved appeals per non ssc avlj is 2 and starting bfkey list is empty and a tied list of 4 keys" do
      let(:tied_appeals_bfkeys) { %w[3 4 5 6] }
      let(:qualifying_appeals_bfkeys) { [] }

      it "adds 2 tied keys to qualifying bfkey list" do
        appeals = job.send(:update_qualifying_appeals_bfkeys, tied_appeals_bfkeys, qualifying_appeals_bfkeys)

        expect(appeals).to eq(%w[3 4])
      end
    end

    context "maximum moved appeals per non ssc avlj is 2 and starting bfkey list of 2 keys and a tied list is empty" do
      let(:tied_appeals_bfkeys) { [] }
      let(:qualifying_appeals_bfkeys) { %w[1 2] }

      it "adds no tied keys to qualifying bfkey list" do
        appeals = job.send(:update_qualifying_appeals_bfkeys, tied_appeals_bfkeys, qualifying_appeals_bfkeys)

        expect(appeals).to eq(%w[1 2])
      end
    end

    context "maximum moved appeals per non ssc avlj is 2 and a starting bfkey list is empty and a tied list is empty" do
      let(:tied_appeals_bfkeys) { [] }
      let(:qualifying_appeals_bfkeys) { [] }

      it "adds no tied keys to qualifying bfkey list and list is empty" do
        appeals = job.send(:update_qualifying_appeals_bfkeys, tied_appeals_bfkeys, qualifying_appeals_bfkeys)

        expect(appeals).to eq([])
      end
    end

    context "maximum moved appeals per non ssc avlj is 2 and a starting bfkey list is empty and a tied list is empty" do
      let(:nonsscavlj_number_of_appeals_to_move_count) { 0 }
      let(:tied_appeals_bfkeys) { %w[3 4 5 6] }
      let(:qualifying_appeals_bfkeys) { %w[1 2] }

      it "raises an error saying the lever has been set incorrectly" do
        appeals = job.send(:update_qualifying_appeals_bfkeys, tied_appeals_bfkeys, qualifying_appeals_bfkeys)

        expect(appeals).to eq(%w[1 2])
      end
    end
  end
end
