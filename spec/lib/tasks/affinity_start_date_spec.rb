# frozen_string_literal: true

describe "affinity_start_date" do
  include_context "rake"
  let!(:judge) { create(:user, :judge, :with_vacols_judge_record) }
  let!(:distribution) { create(:distribution, :completed, :this_month, judge: judge) }
  let!(:old_distribution) { create(:distribution, :completed, :last_month, judge: judge) }

  subject do
    Rake::Task["db:affinity_start_date"].reenable
    Rake::Task["db:affinity_start_date"].invoke
  end

  context "direct_review" do
    let(:output_match) { "" }
    # {most recent distributed appeals with distributed cases from direct review docket}
    let!(:distributed_appeal_drd_priority) do
      appeal = create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
                      receipt_date: 2.days.ago, associated_judge: judge)
      create(:distributed_case, appeal: appeal, distribution: distribution, created_at: 1.day.ago)
      appeal
    end
    let!(:distributed_appeal_drd_nonpriority) do
      appeal = create(:appeal, :direct_review_docket, :assigned_to_judge,
                      receipt_date: 1.week.ago, associated_judge: judge)
      create(:distributed_case, appeal: appeal, distribution: distribution, created_at: 1.day.ago)
      appeal
    end

    # older distributed appeals with distributed cases from direct review docket
    # which should not be selected
    let!(:old_distributed_appeal_drd_priority) do
      appeal = create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
                      receipt_date: 5.days.ago, associated_judge: judge)
      create(:distributed_case, appeal: appeal, distribution: old_distribution, created_at: 2.days.ago)
      appeal
    end
    let!(:old_distributed_appeal_drd_nonpriority) do
      appeal = create(:appeal, :direct_review_docket, :assigned_to_judge,
                      receipt_date: 6.days.ago, associated_judge: judge)
      create(:distributed_case, appeal: appeal, distribution: old_distribution, created_at: 2.days.ago)
      appeal
    end

    # direct review appeals that should be selected
    let!(:ready_appeal_drd_priority) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             receipt_date: 3.days.ago)
    end
    let!(:ready_appeal_drd_priority_with_appeal_affinity) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             :with_appeal_affinity, affinity_start_date: 6.days.ago, receipt_date: 7.days.ago)
    end
    let!(:ready_appeal_drd_nonpriority) do
      create(:appeal, :direct_review_docket, :ready_for_distribution, receipt_date: 2.weeks.ago)
    end

    # direct review appeals that should not be selected
    let!(:non_ready_appeal_drd_priority) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :with_post_intake_tasks)
    end
    let!(:receipt_ready_appeal_drd_priority_not_selectable) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             :with_appeal_affinity, receipt_date: 2.days.ago)
    end
    let!(:ready_appeal_drd_priority_not_selectable) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution)
    end

    it "is successful and adds expected appeal affinity records or values" do
      # Only 2 of the staged appeals should have an affinity
      expect(AppealAffinity.count).to eq 2

      expect { subject }.to output(output_match).to_stdout

      # Only 4 of the staged appeals should have an affinity
      expect(AppealAffinity.count).to eq 4

      # Validate that only the expected appeals are the ones that were updated
      expect(ready_appeal_drd_priority.appeal_affinity).to_not be nil
      expect(ready_appeal_drd_nonpriority.appeal_affinity).to_not be nil
      expect(ready_appeal_drd_priority_with_appeal_affinity.appeal_affinity).to_not be nil
      expect(ready_appeal_drd_priority.appeal_affinity.affinity_start_date).to_not be nil
      expect(ready_appeal_drd_nonpriority.appeal_affinity.affinity_start_date).to_not be nil
      expect(ready_appeal_drd_priority_with_appeal_affinity.appeal_affinity.affinity_start_date).to_not be nil

      expect(non_ready_appeal_drd_priority.appeal_affinity).to be nil
      expect(ready_appeal_drd_priority_not_selectable.appeal_affinity).to be nil
    end
  end
end
