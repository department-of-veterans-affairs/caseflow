# frozen_string_literal: true

describe AppealsDistributed do
  before do
    create(:case_distribution_lever, :request_more_cases_minimum)
  end

  context "#process" do
    let!(:judge) { create(:user, :judge, :with_vacols_judge_record) }
    let!(:direct_review_nonpriority_distribtued_appeal) do
      appeal = create(:appeal, :direct_review_docket, :assigned_to_judge)
      create(:distributed_case, appeal: appeal)
    end
    let!(:evidence_submission_nonpriority_distribtued_appeal) do
      appeal = create(:appeal, :evidence_submission_docket, :assigned_to_judge)
      create(:distributed_case, appeal: appeal)
    end
    let!(:hearing_nonpriority_distribtued_appeal) do
      appeal = create(:appeal, :hearing_docket, :assigned_to_judge)
      create(:distributed_case, appeal: appeal)
    end
    let!(:legacy_nonpriority_distributed_appeal) do
      appeal = create(:case_with_form_9, :assigned, as_judge_assign_task: true)
      create(:legacy_distributed_case, appeal: appeal, priority: false)
    end

    let!(:direct_review_aod_distribtued_appeal) do
      appeal = create(:appeal, :advanced_on_docket_due_to_motion, :direct_review_docket, :assigned_to_judge)
      create(:distributed_case, appeal: appeal)
    end
    let!(:evidence_submission_aod_distribtued_appeal) do
      appeal = create(:appeal, :advanced_on_docket_due_to_age, :evidence_submission_docket, :assigned_to_judge)
      create(:distributed_case, appeal: appeal)
    end
    let!(:hearing_aod_distribtued_appeal) do
      appeal = create(:appeal, :advanced_on_docket_due_to_motion, :hearing_docket, :assigned_to_judge)
      create(:distributed_case, appeal: appeal)
    end
    let!(:legacy_aod_distributed_appeal) do
      appeal = create(:case_with_form_9, :aod, :assigned, as_judge_assign_task: true)
      create(:legacy_distributed_case, appeal: appeal, priority: true)
    end

    let!(:direct_review_cavc_distribtued_appeal) do
      appeal = create(:appeal, :type_cavc_remand, :direct_review_docket, :assigned_to_judge)
      create(:distributed_case, appeal: appeal)
    end
    let!(:evidence_submission_cavc_distribtued_appeal) do
      appeal = create(:appeal, :type_cavc_remand, :evidence_submission_docket, :assigned_to_judge)
      create(:distributed_case, appeal: appeal)
    end
    let!(:hearing_cavc_distribtued_appeal) do
      appeal = create(:appeal, :type_cavc_remand, :hearing_docket, :assigned_to_judge)
      create(:distributed_case, appeal: appeal)
    end
    let!(:legacy_cavc_distributed_appeal) do
      appeal = create(:legacy_cavc_appeal, :assigned, as_judge_assign_task: true, judge: judge.vacols_staff)
      create(:legacy_distributed_case, appeal: appeal, priority: true)
    end

    subject { AppealsDistributed.process }

    it "runs without error with distributed appeals" do
      expect { subject }.not_to raise_error
    end
  end
end
