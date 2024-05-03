# frozen_string_literal: true

describe UpdateAppealAffinityDatesJob do
  context "#format_distributed_case_hash" do
    let(:distributed_cases_hash_from_database) do
      { ["evidence_submission", false] => Time.zone.now,
        ["evidence_submission", true] => Time.zone.now,
        ["direct_review", false] => Time.zone.now,
        ["direct_review", true] => Time.zone.now,
        ["hearing", false] => Time.zone.now,
        ["hearing", true] => Time.zone.now }
    end

    it "deletes the docket/priority pairs which will never need affinities" do
      result = described_class.new.send(:format_distributed_case_hash, distributed_cases_hash_from_database)
      dockets_in_result = result.map { |hash| hash[:docket] }

      expect(result.length).to eq 4
      expect(dockets_in_result).to match_array(%w[evidence_submission direct_review hearing hearing])
    end
  end

  context "#latest_receipt_dates" do
    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:distribution_requested) { create(:distribution, :completed, judge: judge) }
    let(:distribution_current_push) { create(:distribution, :completed, :priority, judge: judge) }
    let(:distribution_old_push) { create(:distribution, :completed, :priority, :this_month, judge: judge) }
    let(:appeal_requested) do
      create(:appeal, :direct_review_docket, :type_cavc_remand, :assigned_to_judge, receipt_date: 1.week.ago)
    end
    let(:appeal_current_push) do
      create(:appeal, :evidence_submission_docket, :type_cavc_remand, :assigned_to_judge, receipt_date: 2.weeks.ago)
    end
    let(:appeal_old_push) { create(:appeal, :hearing_docket, :assigned_to_judge, receipt_date: 1.month.ago) }
    let!(:distributed_case_requested) do
      create(:distributed_case, distribution: distribution_requested, appeal: appeal_requested)
    end
    let!(:distributed_case_current_push) do
      create(:distributed_case, distribution: distribution_current_push, appeal: appeal_current_push)
    end
    let!(:distributed_case_old_push) do
      create(:distributed_case, distribution: distribution_old_push, appeal: appeal_old_push)
    end

    context "from_distribution" do
      it "does not use DistributeCases from any push job" do
        result = described_class.new(distribution_requested.id).send(:latest_receipt_dates_from_distribution)
        dockets = result.map { |hash| hash[:docket] }

        expect(result.length).to eq 1
        expect(dockets).to match_array([appeal_requested.docket_type])
      end
    end

    context "from_push_job" do
      it "only uses DistributedCases from the most recent push job" do
        result = described_class.new.send(:latest_receipt_dates_from_push_job)
        dockets = result.map { |hash| hash[:docket] }

        expect(result.length).to eq 1
        expect(dockets).to match_array([appeal_current_push.docket_type])
      end
    end
  end

  context "#process_ama_appeals_which_need_affinity_updates" do
    let(:hashes_array) do
      [{ docket: "hearing", priority: true, receipt_date: Time.zone.now },
       { docket: "direct_review", priority: true, receipt_date: Time.zone.now },
       { docket: "legacy", priority: true, receipt_date: Time.zone.now }]
    end

    it "doesn't process any legacy appeals" do
      expect_any_instance_of(described_class).to receive(:create_or_update_appeal_affinities).exactly(2).times
      described_class.new.send(:process_ama_appeals_which_need_affinity_updates, hashes_array)
    end
  end

  context "#create_or_update_appeal_affinties" do
    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:distribution) { create(:distribution, :completed, judge: judge) }
    let(:appeal_no_appeal_affinity) { create(:appeal) }
    let(:appeal_with_appeal_affinity_no_start_date) { create(:appeal, :with_appeal_affinity_no_start_date) }

    it "updates existing affinity records if they exist" do
      appeals = [appeal_with_appeal_affinity_no_start_date]
      result = described_class.new(distribution.id).send(:create_or_update_appeal_affinities, appeals, false)

      expect(result.first.affinity_start_date).to_not be nil
      expect(result.first.distribution_id).to eq distribution.id
    end

    it "creates new affinity records if they don't exist" do
      appeals = [appeal_no_appeal_affinity]
      result = described_class.new(distribution.id).send(:create_or_update_appeal_affinities, appeals, false)

      expect(result.first.affinity_start_date).to_not be nil
      expect(result.first.docket).to eq appeal_no_appeal_affinity.docket_type
      expect(result.first.priority).to eq false
      expect(result.first.distribution_id).to eq distribution.id
    end
  end

  context "#perform" do
    it "updates from distribution if provided a distribution_id" do
      expect_any_instance_of(described_class).to receive(:update_from_requested_distribution).and_return(true)
      described_class.new(1).perform_now
    end

    it "updates from the most recent push job if provided no args" do
      expect_any_instance_of(described_class).to receive(:update_from_push_priority_appeals_job).and_return(true)
      described_class.new.perform_now
    end

    it "sends a slack notification if the job errors" do
      allow_any_instance_of(described_class)
        .to receive(:update_from_push_priority_appeals_job).and_raise(StandardError)

      expect_any_instance_of(SlackService).to receive(:send_notification)

      described_class.new.perform_now
    end

    it "runs successfully and adds expected appeal affinity records or values" do

    end
  end
end
