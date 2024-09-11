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
        allow(job).to receive(:send_job_slack_report)
      end

      it "sends a no records moved Slack report and completes the job" do
        job.perform

        # expect(job).to have_received(:send_job_slack_report).with(described_class::NO_RECORDS_FOUND_MESSAGE).once
        expect(job).to have_received(:complete_returned_appeal_job)
          .with(returned_appeal_job, Constants.DISTRIBUTION.no_records_moved_message, []).once
        expect(job).to have_received(:send_job_slack_report).with(described_class::NO_RECORDS_FOUND_MESSAGE).once
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
    let(:job) { described_class.new }

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

  describe "#calculate_remaining_appeals" do
    let(:job) { described_class.new }
    let(:p1) { { "bfkey" => "1", "priority" => 1 } }
    let(:p2) { { "bfkey" => "2", "priority" => 1 } }
    let(:np1) { { "bfkey" => "3", "priority" => 0 } }
    let(:np2) { { "bfkey" => "4", "priority" => 0 } }

    before do
      allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(2)
    end

    context "2 priority and 2 non-priority legacy appeals tied to non-ssc avljs exist" do
      let(:appeals) { [p1, p2, np1, np2] }
      let(:p_appeals_moved) { [p1] }
      let(:np_appeals_moved) { [np1] }

      it "should return the unmoved legacy appeals" do
        returned_reamining_appeals = job.send(:calculate_remaining_appeals, appeals, p_appeals_moved, np_appeals_moved)
        expect(returned_reamining_appeals).to eq([[p2], [np2]])
      end
    end

    context "2 priority legacy appeals tied to non-ssc avljs exist" do
      let(:appeals) { [p1, p2] }
      let(:p_appeals_moved) { [p1] }
      let(:np_appeals_moved) { [] }

      it "should return the unmoved legacy priority appeal and an empty array of non-priority appeals" do
        returned_reamining_appeals = job.send(:calculate_remaining_appeals, appeals, p_appeals_moved, np_appeals_moved)
        expect(returned_reamining_appeals).to eq([[p2], []])
      end
    end

    context "2 non-priority legacy appeals tied to non-ssc avljsexist" do
      let(:appeals) { [np1, np2] }
      let(:p_appeals_moved) { [] }
      let(:np_appeals_moved) { [np1] }

      it "should return the unmoved legacy non-priority appeal and an empty array of priority appeals" do
        returned_reamining_appeals = job.send(:calculate_remaining_appeals, appeals, p_appeals_moved, np_appeals_moved)
        expect(returned_reamining_appeals).to eq([[], [np2]])
      end
    end

    context "all appeals are moved" do
      let(:appeals) { [p1, p2, np1, np2] }
      let(:p_appeals_moved) { [p1, p2] }
      let(:np_appeals_moved) { [np1, np2] }

      it "should return 2 empty arrays" do
        returned_reamining_appeals = job.send(:calculate_remaining_appeals, appeals, p_appeals_moved, np_appeals_moved)
        expect(returned_reamining_appeals).to eq([[], []])
      end
    end

    context "no legacy appeals tied to non-ssc avljs exist" do
      let(:appeals) { [] }
      let(:p_appeals_moved) { [] }
      let(:np_appeals_moved) { [] }

      it "returns an empty array" do
        returned_reamining_appeals = job.send(:calculate_remaining_appeals, appeals, p_appeals_moved, np_appeals_moved)
        expect(returned_reamining_appeals).to_not eq([])
      end
    end
  end

  describe "#filter_appeals" do
    let(:job) { described_class.new }
    let(:non_ssc_avlj1) { create_non_ssc_avlj("NONSSCAN1", "NonScc User1") }
    let(:non_ssc_avlj2) { create_non_ssc_avlj("NONSSCAN2", "NonScc User2") }
    let(:non_ssc_avlj1_sattyid) { non_ssc_avlj1.vacols_staff.sattyid }
    let(:non_ssc_avlj2_sattyid) { non_ssc_avlj2.vacols_staff.sattyid }

    let(:p1) { { "bfkey" => "1", "priority" => 1, "vlj" => non_ssc_avlj1_sattyid } }
    let(:p2) { { "bfkey" => "2", "priority" => 1, "vlj" => non_ssc_avlj2_sattyid } }
    let(:np1) { { "bfkey" => "3", "priority" => 0, "vlj" => non_ssc_avlj2_sattyid } }
    let(:np2) { { "bfkey" => "4", "priority" => 0, "vlj" => non_ssc_avlj1_sattyid } }
    let(:appeals) { [p1, p2, np1, np2] }

    before do
      allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(2)
    end

    context "a single appeal from each of 2 non ssc avljs gets moved" do
      let(:moved_appeals) { [p1, np1] }

      it "returns hash object with correct attributes that match the expected values" do
        returned_filtered_appeals_info = job.send(:filter_appeals, appeals, moved_appeals)
        expected_returned_object = {
          priority_appeals_count: 1,
          non_priority_appeals_count: 1,
          remaining_priority_appeals_count: 1,
          remaining_non_priority_appeals_count: 1,
          grouped_by_avlj: [non_ssc_avlj1.vacols_staff.sattyid, non_ssc_avlj2.vacols_staff.sattyid]
        }
        expect(returned_filtered_appeals_info).to eq(expected_returned_object)
      end
    end

    context "all appeals from each of 2 non ssc avljs gets moved" do
      let(:moved_appeals) { [p1, p2, np1, np2] }

      it "returns hash object with correct attributes that match the expected values" do
        returned_filtered_appeals_info = job.send(:filter_appeals, appeals, moved_appeals)
        expected_returned_object = {
          priority_appeals_count: 2,
          non_priority_appeals_count: 2,
          remaining_priority_appeals_count: 0,
          remaining_non_priority_appeals_count: 0,
          grouped_by_avlj: [non_ssc_avlj1.vacols_staff.sattyid, non_ssc_avlj2.vacols_staff.sattyid]
        }
        expect(returned_filtered_appeals_info).to eq(expected_returned_object)
      end
    end

    context "no appeals are moved" do
      let(:moved_appeals) { [] }

      it "returns hash object with correct attributes that match the expected values" do
        returned_filtered_appeals_info = job.send(:filter_appeals, appeals, moved_appeals)
        expected_returned_object = {
          priority_appeals_count: 0,
          non_priority_appeals_count: 0,
          remaining_priority_appeals_count: 2,
          remaining_non_priority_appeals_count: 2,
          grouped_by_avlj: []
        }
        expect(returned_filtered_appeals_info).to eq(expected_returned_object)
      end
    end

    context "no appeals exist" do
      let(:moved_appeals) { [] }
      let(:appeals) { [] }

      it "returns hash object with correct attributes that match the expected values" do
        returned_filtered_appeals_info = job.send(:filter_appeals, appeals, moved_appeals)
        expected_returned_object = {
          priority_appeals_count: 0,
          non_priority_appeals_count: 0,
          remaining_priority_appeals_count: 0,
          remaining_non_priority_appeals_count: 0,
          grouped_by_avlj: []
        }
        expect(returned_filtered_appeals_info).to eq(expected_returned_object)
      end
    end

    context "an extra priority appeal is moved that wasn't in the original list of appeals" do
      let(:extra_priority_appeal) { { "bfkey" => "5", "priority" => 1, "vlj" => non_ssc_avlj1_sattyid } }
      let(:moved_appeals) { [p1, np1, extra_priority_appeal] }

      it "raises an ERROR" do
        expected_msg = "An invalid priority appeal was detected in the list of moved appeals: "\
                       "#{[extra_priority_appeal]}"

        expect { job.send(:filter_appeals, appeals, moved_appeals) }.to raise_error(StandardError, expected_msg)
      end
    end

    context "an extra non-priority appeal is moved that wasn't in the original list of appeals" do
      let(:extra_non_priority_appeal) { { "bfkey" => "5", "priority" => 0, "vlj" => non_ssc_avlj1_sattyid } }
      let(:moved_appeals) { [p1, np1, extra_non_priority_appeal] }

      it "raises an ERROR" do
        expected_msg = "An invalid non-priority appeal was detected in the list of moved appeals: "\
                       "#{[extra_non_priority_appeal]}"

        expect { job.send(:filter_appeals, appeals, moved_appeals) }.to raise_error(StandardError, expected_msg)
      end
    end
  end

  describe "#create_returned_appeal_job" do
    let(:job) { described_class.new }

    context "when called" do
      it "creates a valid ReturnedAppealJob" do
        allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(2)
        returned_appeal_job = job.send(:create_returned_appeal_job)
        expect(returned_appeal_job.started_at).to be_within(1.second).of(Time.zone.now)
        expect(returned_appeal_job.stats).to eq({ message: "Job started" }.to_json)
      end
    end
  end

  describe "#send_job_slack_report" do
    let(:job) { described_class.new }
    let(:slack_service_instance) { instance_double(SlackService) }

    before do
      allow(SlackService).to receive(:new).and_return(slack_service_instance)
      allow(slack_service_instance).to receive(:send_notification)
    end

    context "is passed a valid message array" do
      let(:message) do
        [
          "Job performed successfully",
          "Total Priority Appeals Moved: 5",
          "Total Non-Priority Appeals Moved: 3",
          "Total Remaining Priority Appeals: 10",
          "Total Remaining Non-Priority Appeals: 7",
          "SATTYIDs of Non-SSC AVLJs Moved: AVJL1, AVJL"
        ]
      end

      it "sends the message successfully" do
        expected_report = "Job performed successfully\n"\
          "Total Priority Appeals Moved: 5\n"\
          "Total Non-Priority Appeals Moved: 3\n"\
          "Total Remaining Priority Appeals: 10\n"\
          "Total Remaining Non-Priority Appeals: 7\n"\
          "SATTYIDs of Non-SSC AVLJs Moved: AVJL1, AVJL"

        job.send(:send_job_slack_report, message)
        expect(slack_service_instance)
          .to have_received(:send_notification)
          .with(expected_report, "ReturnLegacyAppealsToBoardJob")
      end
    end

    context "is passed an empty array" do
      let(:message) { [] }
      it "sends a notification to Slack with the correct message" do
        expected_msg = "Slack message cannot be empty or nil"

        expect { job.send(:send_job_slack_report, message) }.to raise_error(StandardError, expected_msg)
      end
    end
  end

  describe "#move_qualifying_appeals" do
    let(:job) { described_class.new }
    let(:non_ssc_avlj1) { create_non_ssc_avlj("NONSSCAN1", "NonScc User1") }
    let(:non_ssc_avlj2) { create_non_ssc_avlj("NONSSCAN2", "NonScc User2") }
    let(:non_ssc_avlj1_sattyid) { non_ssc_avlj1.vacols_staff.sattyid }
    let(:non_ssc_avlj2_sattyid) { non_ssc_avlj2.vacols_staff.sattyid }

    let(:s1_p_appeal1) { { "bfkey" => "1", "priority" => 1, "vlj" => non_ssc_avlj1_sattyid, "bfd19" => 2.days.ago } }
    let(:s1_p_appeal2) { { "bfkey" => "2", "priority" => 1, "vlj" => non_ssc_avlj1_sattyid, "bfd19" => 2.days.ago } }
    let(:s1_np_appeal1) { { "bfkey" => "3", "priority" => 0, "vlj" => non_ssc_avlj1_sattyid, "bfd19" => 10.days.ago } }
    let(:s1_np_appeal2) { { "bfkey" => "4", "priority" => 0, "vlj" => non_ssc_avlj1_sattyid, "bfd19" => 10.days.ago } }

    let(:s2_p_appeal1) { { "bfkey" => "5", "priority" => 1, "vlj" => non_ssc_avlj2_sattyid, "bfd19" => 2.days.ago } }
    let(:s2_p_appeal2) { { "bfkey" => "6", "priority" => 1, "vlj" => non_ssc_avlj2_sattyid, "bfd19" => 2.days.ago } }
    let(:s2_np_appeal1) { { "bfkey" => "7", "priority" => 0, "vlj" => non_ssc_avlj2_sattyid, "bfd19" => 10.days.ago } }
    let(:s2_np_appeal2) { { "bfkey" => "8", "priority" => 0, "vlj" => non_ssc_avlj2_sattyid, "bfd19" => 10.days.ago } }

    let(:staff1_p_appeals) { [s1_p_appeal1, s1_p_appeal2] }
    let(:staff1_np_appeals) { [s1_np_appeal1, s1_np_appeal2] }
    let(:staff2_p_appeals) { [s2_p_appeal1, s2_p_appeal2] }
    let(:staff2_np_appeals) { [s2_np_appeal1, s2_np_appeal2] }
    let(:appeals) do
      [
        s1_p_appeal1,
        s1_p_appeal2,
        s1_np_appeal1,
        s1_np_appeal2,
        s2_p_appeal1,
        s2_p_appeal2,
        s2_np_appeal1,
        s2_np_appeal2
      ]
    end

    before do
      allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(2)
      allow(VACOLS::Case).to receive(:batch_update_vacols_location)
    end

    context "limit is set to 2 per non ssc avlj" do
      it "moves the 2 priority appeals per non ssc avlj" do
        expected_moved_appeals = [s1_p_appeal1, s1_p_appeal2, s2_p_appeal1, s2_p_appeal2]
        expected_moved_appeal_bf_keys = expected_moved_appeals.map { |m_appeal| m_appeal["bfkey"] }

        moved_appeals = job.send(:move_qualifying_appeals, appeals)

        expect(moved_appeals).to match_array(expected_moved_appeals)
        expect(VACOLS::Case).to have_received(:batch_update_vacols_location)
          .with("63", match_array(expected_moved_appeal_bf_keys))
      end
    end

    context "limit is set to 1 per non ssc avlj" do
      before do
        allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(1)
      end

      it "moves the oldest priority appeals per non ssc avlj" do
        s1_p_appeal1.update("bfd19" => 15.days.ago)
        s1_p_appeal2.update("bfd19" => 20.days.ago)
        s2_p_appeal1.update("bfd19" => 80.days.ago)
        s2_p_appeal2.update("bfd19" => 40.days.ago)

        expected_moved_appeals = [s1_p_appeal2, s2_p_appeal1]
        expected_moved_appeal_bf_keys = expected_moved_appeals.map { |m_appeal| m_appeal["bfkey"] }

        moved_appeals = job.send(:move_qualifying_appeals, appeals)
        expect(moved_appeals).to match_array(expected_moved_appeals)
        expect(VACOLS::Case).to have_received(:batch_update_vacols_location)
          .with("63", match_array(expected_moved_appeal_bf_keys))
      end
    end

    context "limit is set to 10 per non ssc avlj" do
      before do
        allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(10)
      end

      it "moves all appeals" do
        expected_moved_appeals = appeals
        expected_moved_appeal_bf_keys = expected_moved_appeals.map { |m_appeal| m_appeal["bfkey"] }

        moved_appeals = job.send(:move_qualifying_appeals, appeals)
        expect(moved_appeals).to match_array(expected_moved_appeals)
        expect(VACOLS::Case).to have_received(:batch_update_vacols_location)
          .with("63", match_array(expected_moved_appeal_bf_keys))
      end
    end

    context "there are no non_ssc_avljs" do
      before do
        allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(10)
        allow(job).to receive(:non_ssc_avljs).and_return([])
      end

      it "returns and empty array and VACOLS::Case.batch_update_vacols_location does not run doesn't run" do
        expected_moved_appeals = []

        moved_appeals = job.send(:move_qualifying_appeals, appeals)
        expect(moved_appeals).to match_array(expected_moved_appeals)
        expect(VACOLS::Case).to_not have_received(:batch_update_vacols_location)
      end
    end

    context "there are no appeals" do
      it "returns an empty array and VACOLS::Case.batch_update_vacols_location does not run doesn't run" do
        expected_moved_appeals = []

        moved_appeals = job.send(:move_qualifying_appeals, [])
        expect(moved_appeals).to match_array(expected_moved_appeals)
        expect(VACOLS::Case).to_not have_received(:batch_update_vacols_location)
      end
    end

    context "the lever is set with a value 0" do
      before do
        allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(0)
      end

      it "returns an empty array and VACOLS::Case.batch_update_vacols_location does not run doesn't run" do
        expected_moved_appeals = []

        moved_appeals = job.send(:move_qualifying_appeals, appeals)
        expect(moved_appeals).to match_array(expected_moved_appeals)
        expect(VACOLS::Case).to_not have_received(:batch_update_vacols_location)
      end
    end

    context "the lever is set with a value below 0" do
      before do
        allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move).and_return(-1)
      end

      it "it raises an ERROR message and VACOLS::Case.batch_update_vacols_location does not run doesn't run" do
        expected_msg = "CaseDistributionLever.nonsscavlj_number_of_appeals_to_move set below 0"

        expect { job.send(:move_qualifying_appeals, appeals) }.to raise_error(StandardError, expected_msg)
        expect(VACOLS::Case).to_not have_received(:batch_update_vacols_location)
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
        result = job.send(:get_tied_appeal_bfkeys, tied_appeals)
        expect(result).to eq(%w[2 4 1 3])
      end
    end
  end

  describe "#update_qualifying_appeals_bfkeys" do
    let(:job) { described_class.new }
    let(:nonsscavlj_number_of_appeals_to_move_count) { 2 }

    before do
      allow(CaseDistributionLever).to receive(:nonsscavlj_number_of_appeals_to_move)
        .and_return(nonsscavlj_number_of_appeals_to_move_count)
    end

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

    context "lever is set to 0" do
      let(:nonsscavlj_number_of_appeals_to_move_count) { 0 }
      let(:tied_appeals_bfkeys) { %w[3 4 5 6] }
      let(:qualifying_appeals_bfkeys) { %w[1 2] }

      it "returns an unchanged array" do
        appeals = job.send(:update_qualifying_appeals_bfkeys, tied_appeals_bfkeys, qualifying_appeals_bfkeys)

        expect(appeals).to eq(%w[1 2])
      end
    end

    context "lever is set to below 0" do
      let(:nonsscavlj_number_of_appeals_to_move_count) { -1 }
      let(:tied_appeals_bfkeys) { %w[3 4 5 6] }
      let(:qualifying_appeals_bfkeys) { %w[1 2] }
      let(:message) { "CaseDistributionLever.nonsscavlj_number_of_appeals_to_move set below 0" }

      it "raises an error saying the lever has been set incorrectly" do
        expect { job.send(:update_qualifying_appeals_bfkeys, tied_appeals_bfkeys, qualifying_appeals_bfkeys) }
          .to raise_error(StandardError, message)
      end
    end
  end

  def create_non_ssc_avlj(css_id, full_name)
    User.find_by_css_id(css_id) ||
      create(:user, :non_ssc_avlj_user, css_id: css_id, full_name: full_name)
  end
end
