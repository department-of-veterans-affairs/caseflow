# frozen_string_literal: true

describe JudgeDispatchReturnTask, :postgres do
  let(:judge) { create(:user) }
  let(:dispatch_user) { create(:user) }
  let(:dispatch_task) do
    create(:bva_dispatch_task, assigned_to: dispatch_user, parent: create(:root_task))
  end
  let(:params) do
    { assigned_to_id: judge.id, assigned_to_type: User.name, appeal: dispatch_task.appeal, parent_id: dispatch_task.id }
  end
  let(:judge_dispatch_task) { JudgeDispatchReturnTask.create_from_params(params, dispatch_user) }

  describe ".available_actions" do
    subject { judge_dispatch_task.available_actions(judge) }

    context "when judge dispatch return task is assigned to judge" do
      let(:expected_actions) do
        [
          Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
          Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
          Constants.TASK_ACTIONS.REASSIGN_TO_LEGACY_JUDGE.to_h,
          Constants.TASK_ACTIONS.JUDGE_AMA_CHECKOUT.to_h,
          Constants.TASK_ACTIONS.JUDGE_DISPATCH_RETURN_TO_ATTORNEY.to_h,
          Constants.TASK_ACTIONS.CANCEL_TASK.to_h
        ]
      end

      it "should return the right set of actions" do
        expect(subject).to eq(expected_actions)
      end
    end
  end
end
