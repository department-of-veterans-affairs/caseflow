# frozen_string_literal: true

describe EducationRpoCompletedTasksTab, :postgres do
  let(:tab) { EducationRpoCompletedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:edu_regional_processing_office) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an EducationRpoInProgressTasksTab" do
      let(:params) { { assignee: create(:edu_regional_processing_office) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }
    context "when there are tasks completed by the assignee" do
      let!(:assignee_completed_tasks) do
        create_list(:education_assess_documentation_task, 4, :completed, assigned_to: assignee)
      end

      it "does not return the completed tasks" do
        expect(subject).to include(
          [assignee_completed_tasks].flatten
        )
      end
    end
  end
end