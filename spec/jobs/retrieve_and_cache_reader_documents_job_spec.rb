# frozen_string_literal: true

describe RetrieveAndCacheReaderDocumentsJob, :postgres do
  # this job should only retrieve and cache documents that have appeals
  describe ".perform" do
    context "a user has a group of appeals with statuses assigned" do
      let(:user1) { create(:user) }
      let(:appeal1) { create(:appeal) }
      let(:high_priority_task1) do
        create(
          :task,
          assigned_to: user1, status: Constants.TASK_STATUSES.assigned, assigned_to_type: User.name,
          type: JudgeAssignTask.name, appeal: appeal1
        )
      end
      let(:high_priority_task2) do
        create(
          :task,
          assigned_to: user1, status: Constants.TASK_STATUSES.assigned, assigned_to_type: User.name,
          type: JudgeAssignTask.name, appeal: appeal1
        )
      end
      let(:high_priority_task3) do
        create(
          :task,
          assigned_to: user1, status: Constants.TASK_STATUSES.completed, assigned_to_type: User.name,
          type: JudgeAssignTask.name, appeal: appeal1
        )
      end
      it "should return only appeals with status: assigned associated to user." do
        p user1
        p appeal1
        tasks = [high_priority_task1, high_priority_task2]
        p tasks
        allow(BatchAppealsForReaderQuery.process)
        subject { RetrieveAndCacheReaderDocumentsJob.perform_now }
        p subject
        expect(tasks).to match_array([high_priority_task1, high_priority_task2])
      end
    end
  end
end
