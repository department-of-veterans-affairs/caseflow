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

      it "available tasks actions includes Return to EMO action" do
        is_expected.to include Constants.TASK_ACTIONS.REGIONAL_PROCESSING_OFFICE_RETURN_TO_EMO.to_h
      end
    end
  end
end
