# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe CompletedTasksTab, :postgres do
  let(:tab) { CompletedTasksTab.new(params) }
  let(:params) do
    {
      assignee: assignee,
      show_regional_office_column: show_regional_office_column
    }
  end
  let(:assignee) { create(:organization) }
  let(:show_regional_office_column) { false }

  describe ".columns" do
    subject { tab.columns }

    context "when only the assignee argument is passed when instantiating the object" do
      let(:params) { { assignee: create(:organization) } }

      it "returns the correct number of columns" do
        expect(subject.length).to eq(7)
      end

      it "does not include regional office column" do
        expect(subject).to_not include(Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN)
      end
    end

    context "when we want to show the regional office column" do
      let(:show_regional_office_column) { true }

      it "includes the regional office column" do
        expect(subject).to include(Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN)
      end
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee and other folks" do
      let!(:other_folks_tasks) { create_list(:generic_task, 11) }
      let!(:assignee_active_tasks) { create_list(:generic_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_closed_tasks) { create_list(:generic_task, 3, :assigned, assigned_to: assignee) }

      before do
        assignee_closed_tasks.each { |task| task.update!(status: Constants.TASK_STATUSES.completed) }
      end

      it "only returns the assignee's completed tasks" do
        expect(subject).to match_array(assignee_closed_tasks)
      end
    end
  end
end
