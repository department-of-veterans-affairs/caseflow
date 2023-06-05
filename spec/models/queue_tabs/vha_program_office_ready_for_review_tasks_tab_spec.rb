# frozen_string_literal: true

describe VhaProgramOfficeReadyForReviewTasksTab, :postgres do
  let(:tab) { VhaProgramOfficeReadyForReviewTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:vha_program_office) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an VhaProgramOfficeReadyForReviewTasksTab" do
      let(:params) { { assignee: create(:vha_program_office) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee with a completed child AssessDocumentationTask" do
      let!(:other_folks_tasks) { create_list(:assess_documentation_task, 11) }
      let!(:assignee_assigned_tasks) { create_list(:assess_documentation_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_completed_tasks) { create_list(:assess_documentation_task, 4, :completed, assigned_to: assignee) }
      let!(:assignee_on_hold_tasks) { create_list(:assess_documentation_task, 3, :on_hold, assigned_to: assignee) }
      let!(:parent_assigned_tasks_with_children) do
        assignee_on_hold_tasks.map do |task|
          create(:assess_documentation_task, :completed, assigned_to: create(:vha_regional_office), parent: task)
          task.update!(status: Constants.TASK_STATUSES.assigned)
          task
        end
      end

      it "returns ready for review tasks of the assignee and not any other tasks" do
        expect(subject).to match_array(
          [parent_assigned_tasks_with_children].flatten
        )

        expect(subject).not_to include(
          [assignee_completed_tasks].flatten
        )

        expect(subject).not_to include(
          [other_folks_tasks].flatten
        )
      end
    end
  end
end
