# frozen_string_literal: true

describe "affinity_start_date" do
  include_context "rake"

  before { create(:case_distribution_lever, :request_more_cases_minimum) }

  let!(:judge) { create(:user, :judge, :with_vacols_judge_record) }
  let!(:distribution) { create(:distribution, :completed, :this_month, judge: judge) }
  let!(:old_distribution) { create(:distribution, :completed, :last_month, judge: judge) }
  let(:output_match) { "" }

  subject do
    Rake::Task["db:affinity_start_date"].reenable
    Rake::Task["db:affinity_start_date"].invoke
  end

  context "direct_review" do
    # {most recent distributed appeals with distributed cases from direct review docket}
    let!(:distributed_appeal_drd_priority) do
      appeal = create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
                      receipt_date: 2.days.ago, associated_judge: judge)
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

    # direct review appeals that should be selected
    let!(:ready_appeal_drd_priority) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             receipt_date: 3.days.ago)
    end
    let!(:ready_appeal_drd_priority_with_appeal_affinity) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             :with_appeal_affinity, affinity_start_date: 6.days.ago, receipt_date: 7.days.ago)
    end
    let!(:other_ready_appeal_drd_priority) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age,
             :ready_for_distribution, receipt_date: 2.weeks.ago)
    end
    let!(:ready_appeal_drd_priority_no_receipt) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age,
             :ready_for_distribution, receipt_date: 1.week.ago)
    end

    # direct review appeals that should not be selected
    let!(:non_ready_appeal_drd_priority) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :mail_blocking_distribution)
    end
    let!(:receipt_ready_appeal_drd_priority_not_selectable) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             :with_appeal_affinity, affinity_start_date: 1.day.ago, receipt_date: 1.day.ago)
    end

    it "is successful and adds expected appeal affinity records or values" do
      # Only 2 of the staged appeals should have an affinity
      expect(AppealAffinity.count).to eq 2

      expect { subject }.to output(output_match).to_stdout

      # Only 5 of the staged appeals should have an affinity
      expect(AppealAffinity.count).to eq 5

      # Validate that only the expected appeals are the ones that were updated
      expect(ready_appeal_drd_priority.appeal_affinity).to_not be nil
      expect(other_ready_appeal_drd_priority.appeal_affinity).to_not be nil
      expect(ready_appeal_drd_priority_with_appeal_affinity.appeal_affinity).to_not be nil
      expect(ready_appeal_drd_priority.appeal_affinity.affinity_start_date).to_not be nil
      expect(other_ready_appeal_drd_priority.appeal_affinity.affinity_start_date).to_not be nil
      expect(ready_appeal_drd_priority_with_appeal_affinity.appeal_affinity.affinity_start_date).to_not be nil
      expect(ready_appeal_drd_priority_no_receipt.appeal_affinity).to_not be nil

      expect(non_ready_appeal_drd_priority.appeal_affinity).to be nil
      expect(receipt_ready_appeal_drd_priority_not_selectable.appeal_affinity.affinity_start_date.to_date)
        .to eq(1.day.ago.to_date)
    end
  end

  context "evidence_submission" do
    # {most recent distributed appeals with distributed cases from evidence submission docket}
    let!(:distributed_appeal_esd_priority) do
      appeal = create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
                      receipt_date: 3.days.ago, associated_judge: judge)
      create(:distributed_case, appeal: appeal, distribution: distribution, created_at: 1.day.ago)
      appeal
    end

    # older distributed appeals with distributed cases from evidence submission docket
    # which appeals with same receipt date should not be selected
    let!(:old_distributed_appeal_esd_priority) do
      appeal = create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
                      receipt_date: 8.days.ago, associated_judge: judge)
      create(:distributed_case, appeal: appeal, distribution: old_distribution, created_at: 2.days.ago)
      appeal
    end

    # {select}
    let!(:ready_appeal_esd_priority) do
      create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             receipt_date: 4.days.ago)
    end
    let!(:other_ready_appeal_esd_priority) do
      create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age,
             :ready_for_distribution, receipt_date: 3.weeks.ago)
    end
    let!(:receipt_ready_appeal_esd_priority_not_selectable) do
      create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             receipt_date: 8.days.ago)
    end
    let!(:ready_appeal_esd_priority_no_start_date) do
      create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             :with_appeal_affinity_no_start_date, receipt_date: 4.days.ago)
    end

    # {not_select}
    let!(:ready_appeal_esd_priority_not_selectable) do
      create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :ready_for_distribution)
    end
    let!(:non_ready_appeal_esd_priority) do
      create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :with_post_intake_tasks)
    end

    it "is successful and adds expected appeal affinity records or values" do
      expect(AppealAffinity.count).to eq 1

      expect { subject }.to output(output_match).to_stdout

      # Only 8 of the staged appeals should have an affinity
      expect(AppealAffinity.count).to eq 4

      # Validate that only the expected appeals are the ones that were updated
      expect(ready_appeal_esd_priority.appeal_affinity).to_not be nil
      expect(other_ready_appeal_esd_priority.appeal_affinity).to_not be nil
      expect(receipt_ready_appeal_esd_priority_not_selectable.appeal_affinity).to_not be nil
      expect(ready_appeal_esd_priority_no_start_date.appeal_affinity).to_not be nil

      expect(ready_appeal_esd_priority_not_selectable.appeal_affinity).to be nil
      expect(non_ready_appeal_esd_priority.appeal_affinity).to be nil
    end
  end

  context "hearing_request" do
    # {most recent distributed appeals which should be used for appeal selection}
    let!(:distributed_appeal_hrd_priority) do
      appeal = create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
                      receipt_date: 4.days.ago, associated_judge: judge)
      create(:distributed_case, appeal: appeal, distribution: distribution, created_at: 1.day.ago)
      appeal
    end
    let!(:distributed_appeal_hrd_nonpriority) do
      appeal = create(:appeal, :hearing_docket, :assigned_to_judge,
                      receipt_date: 3.weeks.ago, associated_judge: judge)
      create(:distributed_case, appeal: appeal, distribution: distribution, created_at: 1.day.ago)
      appeal
    end

    # {old distributed appeals which should not be used}
    let!(:old_distributed_appeal_hrd_priority) do
      appeal = create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
                      receipt_date: 10.days.ago, associated_judge: judge)
      create(:distributed_case, appeal: appeal, distribution: old_distribution, created_at: 9.days.ago)
      appeal
    end
    let!(:old_distributed_appeal_hrd_nonpriority) do
      appeal = create(:appeal, :hearing_docket, :assigned_to_judge,
                      receipt_date: 11.days.ago, associated_judge: judge)
      create(:distributed_case, appeal: appeal, distribution: old_distribution, created_at: 9.days.ago)
      appeal
    end

    # {select}
    let!(:ready_appeal_hrd_priority) do
      create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             receipt_date: 5.days.ago)
    end
    let!(:ready_appeal_hrd_nonpriority) do
      create(:appeal, :hearing_docket, :ready_for_distribution, receipt_date: 4.weeks.ago)
    end
    let!(:ready_appeal_hrd_priority_no_start_date) do
      create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             :with_appeal_affinity_no_start_date, receipt_date: 5.days.ago)
    end
    let!(:ready_appeal_hrd_nonpriority_no_start_date) do
      create(:appeal, :hearing_docket, :ready_for_distribution, :with_appeal_affinity_no_start_date,
             receipt_date: 4.weeks.ago)
    end
    let!(:ready_appeal_hrd_nonpriority_with_appeal_affinity) do
      create(:appeal, :hearing_docket, :ready_for_distribution, :with_appeal_affinity,
             affinity_start_date: 18.days.ago, receipt_date: 4.weeks.ago)
    end
    # {not select}
    let!(:ready_appeal_hrd_priority_not_selectable) do
      create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :ready_for_distribution)
    end
    let!(:ready_appeal_hrd_nonpriority_not_selectable) do
      create(:appeal, :hearing_docket, :ready_for_distribution)
    end
    let!(:receipt_ready_appeal_hrd_priority_not_selectable) do
      create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             receipt_date: 2.days.ago)
    end
    let!(:receipt_ready_appeal_hrd_nonpriority_not_selectable) do
      create(:appeal, :hearing_docket, :ready_for_distribution, receipt_date: 11.days.ago)
    end
    let!(:non_ready_appeal_hrd_priority) do
      create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :with_post_intake_tasks)
    end
    let!(:non_ready_appeal_hrd_nonpriority) do
      create(:appeal, :hearing_docket, :with_post_intake_tasks)
    end

    it "is successful and adds expected appeal affinity records or values" do
      # Only 8 of the staged appeals should have an affinity
      expect(AppealAffinity.count).to eq 3

      expect { subject }.to output(output_match).to_stdout

      expect(AppealAffinity.count).to eq 5

      # Validate that only the expected appeals are the ones that were updated
      expect(ready_appeal_hrd_priority.appeal_affinity).to_not be nil
      expect(ready_appeal_hrd_nonpriority.appeal_affinity).to_not be nil
      expect(ready_appeal_hrd_priority_no_start_date.appeal_affinity).to_not be nil
      expect(ready_appeal_hrd_nonpriority_no_start_date.appeal_affinity).to_not be nil
      expect(ready_appeal_hrd_nonpriority_with_appeal_affinity.appeal_affinity).to_not be nil

      expect(ready_appeal_hrd_priority_not_selectable.appeal_affinity).to be nil
      expect(ready_appeal_hrd_nonpriority_not_selectable.appeal_affinity).to be nil
      expect(receipt_ready_appeal_hrd_priority_not_selectable.appeal_affinity).to be nil
      expect(receipt_ready_appeal_hrd_nonpriority_not_selectable.appeal_affinity).to be nil
      expect(non_ready_appeal_hrd_priority.appeal_affinity).to be nil
      expect(non_ready_appeal_hrd_nonpriority.appeal_affinity).to be nil
    end
  end

  context "when appeal affinity is nil" do
    let!(:distributed_appeal_hrd_priority) do
      appeal = create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
                      receipt_date: 4.days.ago, associated_judge: judge)
      create(:distributed_case, appeal: appeal, distribution: distribution, created_at: 1.day.ago)
      appeal
    end

    let!(:ready_appeal_hrd_priority) do
      create(:appeal, :hearing_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             receipt_date: 5.days.ago)
    end

    it "successfully creates an appeal affinity with the correct type/priority" do
      expect { subject }.to output(output_match).to_stdout

      expect(ready_appeal_hrd_priority.appeal_affinity).to_not be nil
      expect(ready_appeal_hrd_priority.appeal_affinity.docket).to eq("hearing")
      expect(ready_appeal_hrd_priority.appeal_affinity.priority).to be true
      expect(ready_appeal_hrd_priority.appeal_affinity.affinity_start_date).to_not be nil
      expect(ready_appeal_hrd_priority.appeal_affinity.affinity_start_date)
        .to be_within(1.second).of Time.zone.now
    end
  end

  context "when appeal affinity has no affinity start date" do
    let!(:distributed_appeal_esd_priority) do
      appeal = create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
                      receipt_date: 3.days.ago, associated_judge: judge)
      create(:distributed_case, appeal: appeal, distribution: distribution, created_at: 1.day.ago)
      appeal
    end

    let!(:ready_appeal_esd_priority_no_start_date) do
      create(:appeal, :evidence_submission_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             :with_appeal_affinity_no_start_date, receipt_date: 4.days.ago)
    end

    it "successfully updates the appeal affinity with the correct type/priority" do
      expect { subject }.to output(output_match).to_stdout

      expect(ready_appeal_esd_priority_no_start_date.appeal_affinity).to_not be nil
      expect(ready_appeal_esd_priority_no_start_date.appeal_affinity.affinity_start_date).to_not be nil
      expect(ready_appeal_esd_priority_no_start_date.appeal_affinity.affinity_start_date)
        .to be_within(1.second).of Time.zone.now
    end
  end

  context "when appeal has no matching receipt date" do
    let!(:distributed_appeal_drd_priority) do
      appeal = create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :assigned_to_judge,
                      receipt_date: 5.days.ago, associated_judge: judge)
      create(:distributed_case, appeal: appeal, distribution: distribution, created_at: 1.day.ago)
      appeal
    end

    let!(:ready_appeal_drd_priority) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             receipt_date: 3.days.ago)
    end

    let!(:ready_appeal_drd_priority_with_appeal_affinity) do
      create(:appeal, :direct_review_docket, :advanced_on_docket_due_to_age, :ready_for_distribution,
             :with_appeal_affinity, affinity_start_date: 2.days.ago, receipt_date: 4.days.ago)
    end

    it "does not update or create an appeal_affinity" do
      expect { subject }.to output(output_match).to_stdout

      expect(ready_appeal_drd_priority.appeal_affinity).to be nil
      expect(ready_appeal_drd_priority_with_appeal_affinity.appeal_affinity).to_not be nil
      expect(ready_appeal_drd_priority_with_appeal_affinity.appeal_affinity.affinity_start_date.to_date)
        .to eq(2.days.ago.to_date)
    end
  end
end
