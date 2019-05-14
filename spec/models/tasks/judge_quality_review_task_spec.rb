# frozen_string_literal: true

describe JudgeQualityReviewTask do
  let(:judge) { FactoryBot.create(:user) }
  let(:judge_task) { FactoryBot.create(:ama_judge_task, parent: FactoryBot.create(:root_task), assigned_to: judge) }
  let(:qr_user) { FactoryBot.create(:user) }
  let(:qr_task) { FactoryBot.create(:qr_task, assigned_to: qr_user, parent: judge_task) }
  let(:params) { { assigned_to: judge, appeal: qr_task.appeal, parent_id: qr_task.id } }
  let(:judge_qr_task) { JudgeQualityReviewTask.create_from_params(params, qr_user) }

  describe ".available_actions" do
    subject { judge_qr_task.available_actions(judge) }

    context "when judge quality review task is assigned to judge" do
      let(:expected_actions) do
        [
          Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
          Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.to_h,
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
