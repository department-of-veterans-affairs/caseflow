# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe TrackingTasksTab, :postgres do
  let(:tab) { TrackingTasksTab.new(params) }
  let(:params) { { assignee: assignee } }
  let(:assignee) { create(:organization) }

  describe ".columns" do
    subject { tab.columns }

    it "returns the correct number of columns" do
      expect(subject.length).to eq(4)
    end
  end

  describe ".tasks" do
    subject { tab.tasks }

    context "when there are tasks assigned to the assignee and other folks" do
      let!(:other_folks_tasks) { create_list(:generic_task, 11) }
      let!(:assignee_other_tasks) { create_list(:generic_task, 4, :assigned, assigned_to: assignee) }
      let!(:assignee_tracking_tasks) { create_list(:track_veteran_task, 3, :assigned, assigned_to: assignee) }

      it "only returns the assignee's TrackVeteranTasks" do
        expect(subject).to match_array(assignee_tracking_tasks)
      end
    end
  end
end
