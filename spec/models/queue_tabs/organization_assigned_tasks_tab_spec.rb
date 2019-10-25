# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe OrganizationAssignedTasksTab, :postgres do
  let(:tab) { OrganizationAssignedTasksTab.new(params) }
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

    context "when only the assignee argument is passed when instantiating an OrganizationAssignedTasksTab" do
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

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee and other folks" do
      let!(:other_folks_tasks) { create_list(:generic_task, 11) }
      let!(:assignee_active_tasks) { create_list(:generic_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_on_hold_tasks) { create_list(:generic_task, 3, :assigned, assigned_to: assignee) }
      let!(:on_hold_tasks_children) do
        assignee_on_hold_tasks.map do |task|
          create_list(:generic_task, 2, parent_id: task.id)
          task.update!(status: Constants.TASK_STATUSES.on_hold)
          task.children
        end.flatten
      end

      it "only returns the active tasks that are children of the assignee's on hold tasks" do
        expect(subject).to match_array(on_hold_tasks_children)
      end

      context "when the assignee is a user" do
        let(:assignee) { create(:user) }

        it "raises an error" do
          expect { subject }.to raise_error(Caseflow::Error::MissingRequiredProperty)
        end
      end
    end
  end
end
