# frozen_string_literal: true

describe EducationAssessDocumentationTask, :postgres do
  let(:user) { create(:user) }
  let(:regional_processing_office) { create(:edu_regional_processing_office) }
  let(:task) { create(:education_assess_documentation_task, assigned_to: regional_processing_office) }

  before { regional_processing_office.add_user(user) }

  describe ".label" do
    it "uses a friendly label" do
      expect(task.class.label).to eq COPY::ASSESS_DOCUMENTATION_TASK_LABEL
    end
  end

  context "Task cannot be unassigned" do
    it "task should be assigned to RPO" do
      expect(task.assigned_to).to eq(regional_processing_office)
    end
  end

  describe "#available_actions" do
    context "for regional processing office user" do
      subject { task.available_actions(user) }

      it { is_expected.to eq EducationAssessDocumentationTask::TASK_ACTIONS }
    end
  end
end
