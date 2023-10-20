# frozen_string_literal: true

describe DasDeprecation::AssignTaskToAttorney, :all_dbs do
  before do
    FeatureToggle.enable!(:legacy_das_deprecation)
    User.authenticate!(user: judge)
  end

  after { FeatureToggle.disable!(:legacy_das_deprecation) }

  let!(:vacols_case) { create(:case) }
  let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }

  let(:judge) { create(:user) }
  let!(:vacols_judge) { create(:staff, :judge_role, user: judge) }

  let(:attorney1) { create(:user) }
  let!(:vacols_attorney1) { create(:staff, :attorney_role, user: attorney1) }

  let(:attorney2) { create(:user) }
  let!(:vacols_attorney2) { create(:staff, :attorney_role, user: attorney2) }

  let(:root_task) { create(:root_task, appeal: appeal) }
  let!(:judge_assign_task) { JudgeAssignTask.create!(appeal: appeal, parent: root_task, assigned_to: judge) }

  describe "#should_perform_workflow?" do
    it "feature flag is enabled and appeal has JudgeAssignTask" do
      expect(DasDeprecation::AssignTaskToAttorney.should_perform_workflow?(appeal.id)).to eq(true)
    end
  end

  describe "#create_attorney_task" do
    let!(:task) { DasDeprecation::AssignTaskToAttorney.create_attorney_task(appeal.vacols_id, judge, attorney1).first }

    it "task is a child of JudgeDecisionReviewTask" do
      expect(task.parent.type).to eq("JudgeDecisionReviewTask")
    end

    it "task is AttorneyTask" do
      expect(task.type).to eq("AttorneyTask")
    end

    it "assigns task to attorney" do
      expect(task.assigned_to).to eq(attorney1)
    end

    it "appeal type is LegacyAppeal" do
      expect(task.appeal_type).to eq("LegacyAppeal")
    end
  end

  describe "case reassignment to Attorney" do
    let!(:task1) { DasDeprecation::AssignTaskToAttorney.create_attorney_task(appeal.vacols_id, judge, attorney1).first }
    let!(:task2) { DasDeprecation::AssignTaskToAttorney.reassign_attorney_task(appeal.vacols_id, judge, attorney2) }

    it "reassigns task to another attorney" do
      expect(task2.assigned_to_id).to eq(attorney2.id)
    end
  end
end
