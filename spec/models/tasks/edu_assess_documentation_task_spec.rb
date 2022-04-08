# frozen_string_literal: true

describe EduAssessDocumentationTask, :postgres do
    let(:user) { create(:user) }
  
    context "#available_actions" do
      describe "for regional processing office user" do
        let(:regional_processing_office) { EduRegionalProcessingOffice.create!(name: "Regional Processing Office", url: "Regional Processing Office") }
        let(:regional_processing_office_task) { create(:edu_assess_documentation_task, assigned_to: regional_processing_office) }
  
        before { regional_processing_office.add_user(user) }
  
        subject { regional_processing_office_task.available_actions(user) }
  
        available_actions = [
        #   Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        #   Constants.TASK_ACTIONS.READY_FOR_REVIEW.to_h,
          Constants.TASK_ACTIONS.EDU_REGIONAL_PROCESSING_OFFICE_RETURN_TO_EMO.to_h,
          Constants.TASK_ACTIONS.EDU_READY_FOR_REVIEW.to_h,
          Constants.TASK_ACTIONS.EDU_MARK_TASK_IN_PROGRESS.to_h
        ]
  
        it { is_expected.to eq available_actions }
      end
    end
  end
  