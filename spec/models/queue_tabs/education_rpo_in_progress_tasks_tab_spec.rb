# frozen_string_literal: true

describe EducationRpoInProgressTasksTab, :postgres do
  let(:tab) { EducationRpoInProgressTasksTab.new(params) }
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

    context "when there are tasks in progress to the assignee and other folks" do
      let!(:other_folks_tasks) { create_list(:education_assess_documentation_task, 9) }
      let!(:assignee_in_progress_tasks) do
        create_list(:education_assess_documentation_task, 5, :in_progress, assigned_to: assignee)
      end
      let!(:assignee_assigned_tasks) do
        create_list(:education_assess_documentation_task, 3, :assigned, assigned_to: assignee)
      end

      it "returns in progress tasks of the assignee and not any other tasks" do
        expect(subject).to match_array(
          [assignee_in_progress_tasks].flatten
        )

        expect(subject).not_to include(
          [assignee_assigned_tasks].flatten
        )

        expect(subject).not_to include(
          [other_folks_tasks].flatten
        )
      end
    end
  end
end
