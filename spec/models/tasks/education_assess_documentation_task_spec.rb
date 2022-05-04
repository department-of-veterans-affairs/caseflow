# frozen_string_literal: true

describe EducationAssessDocumentationTask, :postgres do
  let(:user) { create(:user) }
  let(:regional_processing_office) { create(:edu_regional_processing_office) }

  before { regional_processing_office.add_user(user) }

  describe "#available_actions" do
    subject { regional_processing_office_task.available_actions(user) }

    context "for regional processing office user" do
      let(:regional_processing_office_task) do
        create(:education_assess_documentation_task, assigned_to: regional_processing_office)
      end

      it "task should be assigned to RPO" do
        expect(regional_processing_office_task.assigned_to).to eq(regional_processing_office)
      end

      it "in progress action is available whenever task is assigned" do
        is_expected.to include Constants.TASK_ACTIONS.RPO_MARK_TASK_IN_PROGRESS.to_h
      end

      it "in progress action is not available whenever task is already in progress" do
        regional_processing_office_task.in_progress!
        is_expected.to_not include Constants.TASK_ACTIONS.RPO_MARK_TASK_IN_PROGRESS.to_h
      end
    end
  end
end
