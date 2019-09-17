# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe DasDeprecation::AssignTaskToAttorney do
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

  let!(:judge_assign_task) { JudgeAssignTaskCreator.new(appeal: appeal, judge: judge).call }

  describe "#should_perform_workflow?" do
    it "feature flag is enabled and appeal has JudgeAssignTask" do
      expect(DasDeprecation::AssignTaskToAttorney.should_perform_workflow?(appeal.id)).to eq(true)
    end
  end

  describe "#create_attorney_task" do
    let!(:attorney_task) { DasDeprecation::AssignTaskToAttorney.create_attorney_task(appeal.vacols_id, judge, attorney1) }

    it "task is a child of JudgeDecisionReviewTask" do
      expect(attorney_task.parent.type).to eq("JudgeDecisionReviewTask")
    end

    it "task is AttorneyTask" do
      expect(attorney_task.type).to eq("AttorneyTask")
    end

    it "assigns task to attorney" do
      expect(attorney_task.assigned_to).to eq(attorney1)
    end

    it "appeal type is LegacyAppeal" do
      expect(attorney_task.appeal_type).to eq("LegacyAppeal")
    end
  end

  describe "case reassignment to Attorney" do
    let!(:attorney_task1) { DasDeprecation::AssignTaskToAttorney.create_attorney_task(appeal.vacols_id, judge, attorney1) }
    let!(:attorney_task2) { DasDeprecation::AssignTaskToAttorney.reassign_attorney_task(appeal.vacols_id, judge, attorney2) }

    it "cancels task" do
      task = AttorneyTask.find_by(appeal_id: LegacyAppeal.find_by(vacols_id: appeal.vacols_id).id)

      expect(task.status).to eq(Constants.TASK_STATUSES.cancelled)
    end

    it "reassigns task to another attorney" do
      expect(attorney_task2.assigned_to).to eq(attorney2)
    end
  end
end
