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
        expect(subject.length).to eq 8
      end
    end
  end

  describe ".label" do
    subject { tab.label }

    it do
      is_expected.to eq COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE
      is_expected.to eq "Assigned (%d)"
    end
  end

  describe ".description" do
    subject { tab.description }

    it do
      is_expected.to eq "Cases assigned to a member of the #{assignee.name} team:"
    end
  end

  describe ".self.tab_name" do
    subject { described_class.tab_name }

    it "matches expected tab name" do
      is_expected.to eq(Constants.QUEUE_CONFIG.VHA_PO_ASSIGNED_TASKS_TAB_NAME)
      is_expected.to eq("po_assigned")
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
