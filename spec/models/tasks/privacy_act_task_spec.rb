# frozen_string_literal: true

describe Task, :postgres do
  describe ".available_actions" do
    let(:task) { nil }
    let(:user) { nil }
    subject { task.available_actions(user) }

    context "when task is assigned to user" do
      let(:task) { PrivacyActTask.find(create(:privacy_act_task).id) }
      let(:user) { task.assigned_to }
      let(:expected_actions) do
        [
          Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
          Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
          Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
          Constants.TASK_ACTIONS.CANCEL_TASK.to_h
        ]
      end
      it "should return team assign, person reassign, complete, and cancel actions" do
        expect(subject).to eq(expected_actions)
      end
    end
  end
end
