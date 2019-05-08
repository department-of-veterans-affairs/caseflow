# frozen_string_literal: true

describe JudgeDispatchReturnTask do
  let(:judge) { FactoryBot.create(:user) }
  let(:judge_task) { FactoryBot.create(:ama_judge_task, parent: FactoryBot.create(:root_task), assigned_to: judge) }
  let(:dispatch_user) { FactoryBot.create(:user) }
  let(:dispatch_task) { FactoryBot.create(:bva_dispatch_task, assigned_to: dispatch_user, parent: judge_task) }
  let(:params) { { assigned_to: judge, appeal: dispatch_task.appeal, parent_id: dispatch_task.id } }
  let(:judge_dispatch_task) { JudgeDispatchReturnTask.create_from_params(params, dispatch_user) }

  describe ".available_actions" do
    subject { judge_dispatch_task.available_actions(judge) }

    context "when judge dispatch return task is assigned to judge" do
      let(:expected_actions) do
        [
          Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
          Constants.TASK_ACTIONS.ASSIGN_TO_ATTORNEY.to_h,
          Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
          Constants.TASK_ACTIONS.CANCEL_TASK.to_h
        ]
      end

      it "should return the right set of actions" do
        expect(subject).to eq(expected_actions)
      end
    end
  end
end
