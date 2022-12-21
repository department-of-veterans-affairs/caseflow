# frozen_string_literal: true

describe RetrieveAndCacheReaderDocumentsJob, :postgres do
  describe ".perform" do
    context "users have appeals with statuses assigned" do
      let(:user1) { create(:user) }
      let(:appeal1) { create(:appeal) }
      let(:user2) { create(:user) }
      let(:appeal2) { create(:appeal) }
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
          :ama_task,
          assigned_to: user2, status: Constants.TASK_STATUSES.assigned, assigned_to_type: User.name,
          type: JudgeAssignTask.name, appeal: appeal2
        )
      end
      let(:high_priority_task4) do
        create(
          :task,
          assigned_to: user2, status: Constants.TASK_STATUSES.assigned, assigned_to_type: User.name,
          type: JudgeAssignTask.name, appeal: appeal2
        )
      end

      subject { RetrieveAndCacheReaderDocumentsJob.perform_now }

      before do
        tasks = [high_priority_task1, high_priority_task2, high_priority_task3, high_priority_task4]
      end

      it "should only fetch Task assigned to user" do
        returned_user1_task1 = subject.to_a[0][1][0]
        returned_user2_task3 = subject.to_a[1][1][0]

        expect(returned_user1_task1.assigned_to_id).to eq(user1.id)
        expect(returned_user1_task1.assigned_to_id).to_not eq(user2.id)
        expect(returned_user2_task3.assigned_to_id).to eq(user2.id)
        expect(returned_user2_task3.assigned_to_id).to_not eq(user1.id)
      end
      it "should only fetch appeals with status: assigned associated to user." do
        returned_user2 = subject.to_a[0][0]

        expect(user2.efolder_documents_fetched_at).to be_nil
        expect(returned_user2.efolder_documents_fetched_at).to_not be_nil
      end
    end
  end
end
