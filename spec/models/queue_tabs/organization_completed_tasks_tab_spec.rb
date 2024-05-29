# frozen_string_literal: true

describe OrganizationCompletedTasksTab, :postgres do
  let(:tab) { OrganizationCompletedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee,
      show_regional_office_column: show_regional_office_column
    }
  end
  let(:assignee) { create(:organization) }
  let(:show_regional_office_column) { false }

  describe ".column_names" do
    subject { tab.column_names }

    context "when only the assignee argument is passed when instantiating a OrganizationCompletedTasksTab" do
      let(:params) { { assignee: create(:organization) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end

      it "does not include regional office column" do
        expect(subject).to_not include(Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name)
      end
    end

    context "when we want to show the regional office column" do
      let(:show_regional_office_column) { true }

      it "includes the regional office column" do
        expect(subject).to include(Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name)
      end
    end
  end

  describe ".description" do
    subject { tab.description }

    context "when we want to show the amount of cases completed in the last 7 days" do
      it "has the correct description for each tab" do
        expect(subject).to eq(COPY::QUEUE_PAGE_COMPLETE_LAST_SEVEN_DAYS_TASKS_DESCRIPTION)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee and other folks" do
      let!(:other_folks_tasks) { create_list(:ama_task, 11) }
      let!(:assignee_active_tasks) { create_list(:ama_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_closed_tasks) { create_list(:ama_task, 3, :assigned, assigned_to: assignee) }

      before do
        assignee_closed_tasks.each { |task| task.update!(status: Constants.TASK_STATUSES.completed) }
      end

      it "only returns the assignee's completed tasks" do
        expect(subject).to match_array(assignee_closed_tasks)
      end
    end
  end
end
