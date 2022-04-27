# frozen_string_literal: true
describe EducationRpoAssignedTasksTab, :postgres do
  let(:tab) { EducationRpoAssignedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:edu_regional_processing_office) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an EducationRpoAssignedTasksTab" do
      let(:params) { { assignee: create(:edu_regional_processing_office) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(4)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }
    context "when there are tasks assigned to rpo" do
      let(:assignee_active_tasks) { create_list(:education_assess_documentation_task, 4, :assigned, assigned_to: assignee) }
      it "returns assigned tasks" do
        expect(subject).to match_array(assignee_active_tasks)
      end
    end
    context "the appeal does not appear on the RPO Assigned tab " do
      let(:assignee_active_tasks) { create_list(:education_assess_documentation_task, 4, :assigned, assigned_to: assignee) }
      it "when sent to EMO " do
        end
      it "when sent to Bva Intake" 
      do 
       
      end
      it "when a task is set to Rpo"
  end
end