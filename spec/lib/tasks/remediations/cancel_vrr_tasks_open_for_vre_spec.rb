# frozen_string_literal: true

describe "remediations/cancel_vrr_tasks_open_for_vre" do
  include_context "rake"

  describe "remediations:cancel_vrr_tasks_open_for_vre" do
    it "delegates to CancelTasksAndDescendants" do
      task_relation = double("task_relation")

      expect(CancelTasksAndDescendants::VeteranRecordRequestsOpenForVREQuery)
        .to receive(:call).and_return(task_relation)

      expect(CancelTasksAndDescendants).to receive(:call).with(task_relation)

      Rake::Task["remediations:cancel_vrr_tasks_open_for_vre"].invoke
    end
  end
end
