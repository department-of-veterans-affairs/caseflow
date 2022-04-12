# frozen_string_literal: true

describe EducationAssessDocumentationTask, :postgres do
    let(:user) { create(:user) }
  
    context "#available_actions" do
      describe "for regional processing office user" do
        let(:regional_processing_office) { EduRegionalProcessingOffice.create!(name: "Regional Processing Office", url: "Regional Processing Office") }
        let(:regional_processing_office_task) { create(:education_assess_documentation_task, assigned_to: regional_processing_office) }
        
        it "task should be assigned to RPO" do
           expect(regional_processing_office_task.assigned_to).to eq(regional_processing_office)
        end

        before { regional_processing_office.add_user(user) }
  
        subject { regional_processing_office_task.available_actions(user) }
  
        available_actions = []
  
        it { is_expected.to eq available_actions }
      end
    end
  end
  