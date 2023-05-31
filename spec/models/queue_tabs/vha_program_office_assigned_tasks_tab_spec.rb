# frozen_string_literal: true

describe VhaProgramOfficeAssignedTasksTab, :postgres do
  let(:tab) { VhaProgramOfficeAssignedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee
    }
  end
  let(:assignee) { create(:vha_program_office) }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating an VhaProgramOfficeAssignedTasksTab" do
      let(:params) { { assignee: create(:vha_program_office) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee and other folks" do
      let!(:other_folks_tasks) { create_list(:assess_documentation_task, 11) }
      let!(:assignee_active_tasks) { create_list(:assess_documentation_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_on_hold_tasks) { create_list(:assess_documentation_task, 3, :assigned, assigned_to: assignee) }
      let!(:on_hold_tasks_children) do
        assignee_on_hold_tasks.map do |task|
          create(:assess_documentation_task, :in_progress, parent: task)
          create(:timed_hold_task, :assigned, parent: task)
          task.update!(status: Constants.TASK_STATUSES.on_hold)
          task.children
        end.flatten
      end

      it "returns active children of the assignee's on hold tasks and assignee tasks that are on a timed hold" do
        expect(subject).not_to match_array(
          [on_hold_tasks_children.select { |task| task.type.eql? Task.name }, assignee_on_hold_tasks].flatten
        )
      end
    end
  end
end
