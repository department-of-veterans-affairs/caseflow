# frozen_string_literal: true

describe EducationAssessDocumentationTask, :postgres do
  let(:user) { create(:user) }
  let(:education_rpo) { create(:education_rpo) }
  let(:task) { create(:education_assess_documentation_task, assigned_to: education_rpo) }

  before { education_rpo.add_user(user) }

  describe ".label" do
    it "uses a friendly label" do
      expect(task.class.label).to eq COPY::ASSESS_DOCUMENTATION_TASK_LABEL
    end
  end

  context "Task cannot be unassigned" do
    it "task should be assigned to RPO" do
      expect(task.assigned_to).to eq(education_rpo)
    end
  end

  describe "#available_actions" do
    subject { task.available_actions(user) }

    context "for regional processing office user" do
      it do
        is_expected.to match_array EducationAssessDocumentationTask::TASK_ACTIONS +
                                   [Constants.TASK_ACTIONS.EDUCATION_RPO_MARK_TASK_IN_PROGRESS.to_h]
      end

      it "available tasks actions includes Return to EMO action" do
        is_expected.to include Constants.TASK_ACTIONS.EDUCATION_RPO_RETURN_TO_EMO.to_h
      end

      it "in progress action is available whenever task is assigned" do
        is_expected.to include Constants.TASK_ACTIONS.EDUCATION_RPO_MARK_TASK_IN_PROGRESS.to_h
      end

      it "in progress action is not available whenever task is already in progress" do
        task.in_progress!
        is_expected.to_not include Constants.TASK_ACTIONS.EDUCATION_RPO_MARK_TASK_IN_PROGRESS.to_h
      end
    end
  end
end
