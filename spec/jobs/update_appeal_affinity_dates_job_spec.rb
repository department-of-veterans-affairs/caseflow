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
    before { Seeds::CaseDistributionLevers.new.seed! }

    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:distribution_requested) { create(:distribution, :completed, judge: judge) }
    let(:distribution_requested_older) { create(:distribution, :completed, :this_month, judge: judge) }
    let(:distribution_current_push) { create(:distribution, :completed, :priority, judge: judge) }
    let(:distribution_old_push) { create(:distribution, :completed, :priority, :this_month, judge: judge) }
    let(:appeal_requested) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
             receipt_date: 1.week.ago)
    end
    let(:appeal_requested_older) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
             receipt_date: 1.year.ago)
    end
    let(:appeal_current_push) do
      create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
             receipt_date: 2.weeks.ago)
    end
    let(:appeal_old_push) { create(:appeal, :hearing_docket, :assigned_to_judge, receipt_date: 1.month.ago) }
    let!(:distributed_case_requested) do
      create(:distributed_case, distribution: distribution_requested, appeal: appeal_requested)
    end
    let!(:distributed_case_requested_older) do
      create(:distributed_case, distribution: distribution_requested_older, appeal: appeal_requested_older)
    end
    let!(:distributed_case_current_push) do
      create(:distributed_case, distribution: distribution_current_push, appeal: appeal_current_push)
    end
    let!(:distributed_case_old_push) do
      create(:distributed_case, distribution: distribution_old_push, appeal: appeal_old_push)
    end

    context "from_distribution" do
      it "does not use DistributeCases from any push job and gets most recent receipt date" do
        job = described_class.new
        job.instance_variable_set(:@distribution_id, distribution_requested.id)
        result = job.send(:latest_receipt_dates_from_distribution)

        expect(result.length).to eq 1
        expect(result.first[:docket]).to eq appeal_requested.docket_type
        expect(result.first[:receipt_date]).to eq appeal_requested.receipt_date
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

  context "when there are no query results" do
    it "#latest_receipt_dates_from_push_job does not error" do
      result = described_class.new.send(:latest_receipt_dates_from_push_job)
      expect(result).to eq []
    end

    it "#process_ama_appeals_which_need_affinity_updates doesn't error or call #create_or_update_appeal_affinities" do
      expect_any_instance_of(described_class).to_not receive(:create_or_update_appeal_affinities)
      result = described_class.new.send(:process_ama_appeals_which_need_affinity_updates, [])
      expect(result).to eq []
    end

    it "#perform does not call #process_ama_appeals_which_need_affinity_updates" do
      expect_any_instance_of(described_class).to_not receive(:process_ama_appeals_which_need_affinity_updates)
      described_class.perform_now
    end
  end

  context "#process_ama_appeals_which_need_affinity_updates" do
    let(:hashes_array) do
      [{ docket: "hearing", priority: true, receipt_date: Time.zone.now },
       { docket: "direct_review", priority: true, receipt_date: Time.zone.now },
       { docket: "legacy", priority: true, receipt_date: Time.zone.now }]
    end

    subject { described_class.new.send(:process_ama_appeals_which_need_affinity_updates, hashes_array) }

    it "doesn't process any legacy appeals" do
      expect_any_instance_of(described_class).to receive(:create_or_update_appeal_affinities).exactly(2).times
      subject
    end

    context "for single docket/priority combinations" do
      let!(:direct_review_priority) do
        create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
               receipt_date: 1.day.ago)
      end
      let!(:direct_review_nonpriority) do
        create(:appeal, :direct_review_docket, :ready_for_distribution, receipt_date: 1.day.ago)
      end
      let!(:evidence_submission_priority) do
        create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_motion, :ready_for_distribution,
               receipt_date: 1.day.ago)
      end
      let!(:evidence_submission_nonpriority) do
        create(:appeal, :evidence_submission_docket, :ready_for_distribution, receipt_date: 1.day.ago)
      end
      let!(:hearing_priority) do
        create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
               receipt_date: 1.day.ago)
      end
      let!(:hearing_nonpriority) do
        create(:appeal, :hearing_docket, :ready_for_distribution, receipt_date: 1.day.ago)
      end

      context "for direct review priority" do
        let(:hashes_array) { [{ docket: "direct_review", priority: true, receipt_date: Time.zone.now }] }

        it "only queries for and passes along direct review priority appeals" do
          expect_any_instance_of(described_class)
            .to receive(:create_or_update_appeal_affinities)
            .with([direct_review_priority], hashes_array.first[:priority])

          subject
        end
      end

      context "for evidence submission priority" do
        let(:hashes_array) { [{ docket: "evidence_submission", priority: true, receipt_date: Time.zone.now }] }

        it "only queries for and passes along evidence submission priority appeals" do
          expect_any_instance_of(described_class)
            .to receive(:create_or_update_appeal_affinities)
            .with([evidence_submission_priority], hashes_array.first[:priority])

          subject
        end
      end

      context "for hearing priority" do
        let(:hashes_array) { [{ docket: "hearing", priority: true, receipt_date: Time.zone.now }] }

        it "only queries for and passes along hearing priority appeals" do
          expect_any_instance_of(described_class)
            .to receive(:create_or_update_appeal_affinities)
            .with([hearing_priority], hashes_array.first[:priority])

          subject
        end
      end

      context "for hearing nonpriority" do
        let(:hashes_array) { [{ docket: "hearing", priority: false, receipt_date: Time.zone.now }] }

        it "only queries for and passes along hearing nonpriority appeals" do
          expect_any_instance_of(described_class)
            .to receive(:create_or_update_appeal_affinities)
            .with([hearing_nonpriority], hashes_array.first[:priority])

          subject
        end
      end
    end
  end

  context "#process_legacy_appeals_which_need_affinity_updates" do
    let(:hashes_array) do
      [{ docket: "hearing", priority: true, receipt_date: Time.zone.now },
       { docket: "direct_review", priority: true, receipt_date: Time.zone.now },
       { docket: "legacy", priority: true, receipt_date: Time.zone.now }]
    end

    subject { described_class.new.send(:process_legacy_appeals_which_need_affinity_updates, hashes_array) }

    it "processes only legacy appeals" do
      expect_any_instance_of(described_class).to receive(:create_or_update_appeal_affinities).exactly(1).times
      subject
    end
  end

  context "#process_legacy_appeals_which_need_affinity_updates" do
    let(:hashes_array) do
      [{ docket: "hearing", priority: true, receipt_date: Time.zone.now },
       { docket: "direct_review", priority: true, receipt_date: Time.zone.now },
       { docket: "legacy", priority: true, receipt_date: Time.zone.now }]
    end

    subject { described_class.new.send(:process_legacy_appeals_which_need_affinity_updates, hashes_array) }

    it "processes only legacy appeals" do
      expect_any_instance_of(described_class).to receive(:create_or_update_appeal_affinities).exactly(1).times
      subject
    end
  end

  context "#create_or_update_appeal_affinties" do
    before { Seeds::CaseDistributionLevers.new.seed! }

    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:distribution) { create(:distribution, :completed, judge: judge) }
    let(:appeal_no_appeal_affinity) { create(:appeal) }
    let(:appeal_with_appeal_affinity_no_start_date) { create(:appeal, :with_appeal_affinity_no_start_date) }
    let(:job) { described_class.new }

    before { job.instance_variable_set(:@distribution_id, distribution.id) }

    it "updates existing affinity records if they exist" do
      appeals = [appeal_with_appeal_affinity_no_start_date]
      result = job.send(:create_or_update_appeal_affinities, appeals, false)

      expect(result.first.affinity_start_date).to_not be nil
      expect(result.first.distribution_id).to eq distribution.id
    end

    it "creates new affinity records if they don't exist" do
      appeals = [appeal_no_appeal_affinity]
      result = job.send(:create_or_update_appeal_affinities, appeals, false)

      expect(result.first.affinity_start_date).to_not be nil
      expect(result.first.docket).to eq appeal_no_appeal_affinity.docket_type
      expect(result.first.priority).to eq false
      expect(result.first.distribution_id).to eq distribution.id
    end
  end

  context "#legacy_appeals_with_no_appeal_affinities" do
    before { Seeds::CaseDistributionLevers.new.seed! }

    let(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:distribution) { create(:distribution, :completed, judge: judge) }
    let(:appeal_no_appeal_affinity) { create(:case) }
    let(:appeal_with_appeal_affinity) { create(:case, :with_appeal_affinity) }
    let(:appeal_with_appeal_affinity_no_start_date) { create(:case, :with_appeal_affinity, affinity_start_date: nil) }
    let(:job) { described_class.new }
    let(:appeal_no_affinity_hash) do
      { "bfkey" => appeal_no_appeal_affinity.bfkey,
        "bfd19" => appeal_no_appeal_affinity.bfd19 }
    end
    let(:appeal_with_affinity_hash) do
      { "bfkey" => appeal_with_appeal_affinity.bfkey,
        "bfd19" => appeal_with_appeal_affinity.bfd19 }
    end
    let(:appeal_with_affinity_no_start_date_hash) do
      { "bfkey" => appeal_with_appeal_affinity_no_start_date.bfkey,
        "bfd19" => appeal_with_appeal_affinity_no_start_date.bfd19 }
    end

    before { job.instance_variable_set(:@distribution_id, distribution.id) }

    it "only returns appeals with no affinity records or affinity start dates" do
      appeals = [appeal_with_affinity_hash, appeal_no_affinity_hash, appeal_with_affinity_no_start_date_hash]
      result = job.send(:legacy_appeals_with_no_appeal_affinities, appeals)

      expect(result.count).to eq 2
    end
  end

  context "#perform" do
    it "updates from distribution if provided a distribution_id" do
      expect_any_instance_of(described_class).to receive(:update_from_requested_distribution).and_return(true)
      described_class.perform_now(1)
    end

    it "updates from the most recent push job if provided no args" do
      expect_any_instance_of(described_class).to receive(:update_from_push_priority_appeals_job).and_return(true)
      described_class.perform_now
    end

    it "sends a slack notification if the job errors" do
      allow_any_instance_of(described_class)
        .to receive(:update_from_push_priority_appeals_job).and_raise(StandardError)

      expect_any_instance_of(SlackService).to receive(:send_notification)

      described_class.perform_now
    end

    context "full run" do
      before { Seeds::CaseDistributionLevers.new.seed! }

      let!(:judge) { create(:user, :judge, :with_vacols_judge_record) }
      let!(:previous_distribution) { create(:distribution, :completed, :this_month, judge: judge) }

      # previously distributed appeals with distributed cases from each docket and priority combination
      let!(:distributed_appeal_drd_priority) do
        appeal = create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
                        receipt_date: 2.days.ago, associated_judge: judge)
        create(:distributed_case, appeal: appeal, distribution: previous_distribution)
        appeal
      end
      let!(:distributed_appeal_drd_nonpriority) do
        appeal = create(:appeal, :direct_review_docket, :assigned_to_judge,
                        receipt_date: 1.week.ago, associated_judge: judge)
        create(:distributed_case, appeal: appeal, distribution: previous_distribution)
        appeal
      end
      let!(:distributed_appeal_esd_priority) do
        appeal = create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
                        receipt_date: 3.days.ago, associated_judge: judge)
        create(:distributed_case, appeal: appeal, distribution: previous_distribution)
        appeal
      end
      let!(:distributed_appeal_esd_nonpriority) do
        appeal = create(:appeal, :evidence_submission_docket, :assigned_to_judge,
                        receipt_date: 2.weeks.ago, associated_judge: judge)
        create(:distributed_case, appeal: appeal, distribution: previous_distribution)
        appeal
      end
      let!(:distributed_appeal_hrd_priority) do
        appeal = create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
                        receipt_date: 4.days.ago, associated_judge: judge)
        create(:distributed_case, appeal: appeal, distribution: previous_distribution)
        appeal
      end
      let!(:distributed_appeal_hrd_nonpriority) do
        appeal = create(:appeal, :hearing_docket, :assigned_to_judge,
                        receipt_date: 3.weeks.ago, associated_judge: judge)
        create(:distributed_case, appeal: appeal, distribution: previous_distribution)
        appeal
      end

      # ready appeals from each docket and priority combination without existing affinity records
      let!(:ready_appeal_drd_priority) do
        create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
               receipt_date: 3.days.ago)
      end
      let!(:ready_appeal_drd_nonpriority) do
        create(:appeal, :direct_review_docket, :ready_for_distribution, receipt_date: 2.weeks.ago)
      end
      let!(:ready_appeal_esd_priority) do
        create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
               receipt_date: 4.days.ago)
      end
      let!(:ready_appeal_esd_nonpriority) do
        create(:appeal, :evidence_submission_docket, :ready_for_distribution, receipt_date: 3.weeks.ago)
      end
      let!(:ready_appeal_hrd_priority) do
        create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
               receipt_date: 5.days.ago)
      end
      let!(:ready_appeal_hrd_nonpriority) do
        create(:appeal, :hearing_docket, :ready_for_distribution, receipt_date: 4.weeks.ago)
      end

      # ready appeals from each docket and priority combination with existing affinity records but no start date
      let!(:ready_appeal_drd_priority_no_start_date) do
        create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
               :with_appeal_affinity_no_start_date, receipt_date: 3.days.ago)
      end
      let!(:ready_appeal_esd_priority_no_start_date) do
        create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
               :with_appeal_affinity_no_start_date, receipt_date: 4.days.ago)
      end
      let!(:ready_appeal_hrd_priority_no_start_date) do
        create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
               :with_appeal_affinity_no_start_date, receipt_date: 5.days.ago)
      end
      let!(:ready_appeal_hrd_nonpriority_no_start_date) do
        create(:appeal, :hearing_docket, :ready_for_distribution, :with_appeal_affinity_no_start_date,
               receipt_date: 4.weeks.ago)
      end

      # ready appeals from each docket and priority combination which should not be selected
      let!(:ready_appeal_drd_priority_not_selectable) do
        create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution)
      end
      let!(:ready_appeal_esd_priority_not_selectable) do
        create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :ready_for_distribution)
      end
      let!(:ready_appeal_hrd_priority_not_selectable) do
        create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :ready_for_distribution)
      end
      let!(:ready_appeal_hrd_nonpriority_not_selectable) do
        create(:appeal, :hearing_docket, :ready_for_distribution)
      end

      # non-ready appeals from each docket and priority combination
      let!(:non_ready_appeal_drd_priority) do
        create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :with_post_intake_tasks)
      end
      let!(:non_ready_appeal_esd_priority) do
        create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :with_post_intake_tasks)
      end
      let!(:non_ready_appeal_hrd_priority) do
        create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :with_post_intake_tasks)
      end
      let!(:non_ready_appeal_hrd_nonpriority) do
        create(:appeal, :hearing_docket, :with_post_intake_tasks)
      end

      # legacy appeal distributed
      let!(:distributed_legacy_case) do
        legacy_appeal = create(:case, :tied_to_judge, :type_original, tied_judge: judge, bfd19: 3.weeks.ago)
        create(:legacy_distributed_case, appeal: legacy_appeal, distribution: previous_distribution, priority: false)
        legacy_appeal
      end

      # legacy appeals ready for distribution
      let!(:legacy_appeal_no_appeal_affinity) { create(:case, :ready_for_distribution, :type_original) }
      let!(:legacy_appeal_no_appeal_affinity_no_start_date) do
        create(:case, :ready_for_distribution, :type_original, :with_appeal_affinity, affinity_start_date: nil)
      end
      let!(:legacy_appeal_with_appeal_affinity) do
        create(:case, :ready_for_distribution, :with_appeal_affinity, :type_original)
      end
      let!(:legacy_appeal_no_appeal_affinity_later_bfd19) do
        create(:case, :ready_for_distribution, :type_original, bfd19: 1.week.ago)
      end

      it "is successful and adds expected appeal affinity records or values" do
        described_class.perform_now(previous_distribution.id)

        # Only 11 of the staged appeals should have an affinity
        expect(AppealAffinity.count).to eq 11

        # Validate that only the expected appeals are the ones that were updated
        expect(ready_appeal_drd_priority.appeal_affinity).to_not be nil
        expect(ready_appeal_esd_priority.appeal_affinity).to_not be nil
        expect(ready_appeal_hrd_priority.appeal_affinity).to_not be nil
        expect(ready_appeal_hrd_nonpriority.appeal_affinity).to_not be nil
        expect(ready_appeal_drd_priority_no_start_date.appeal_affinity).to_not be nil
        expect(ready_appeal_esd_priority_no_start_date.appeal_affinity).to_not be nil
        expect(ready_appeal_hrd_priority_no_start_date.appeal_affinity).to_not be nil
        expect(ready_appeal_hrd_nonpriority_no_start_date.appeal_affinity).to_not be nil
        expect(legacy_appeal_no_appeal_affinity.appeal_affinity).to_not be nil
        expect(legacy_appeal_no_appeal_affinity_no_start_date.appeal_affinity).to_not be nil
        expect(legacy_appeal_no_appeal_affinity_later_bfd19.appeal_affinity).to be nil
      end
    end
  end
end
