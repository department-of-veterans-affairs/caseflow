# frozen_string_literal: true

describe SendInitialNotificationLetterTask do
  let(:user) { create(:user) }
  let(:cob_team) { ClerkOfTheBoard.singleton }
  let(:root_task) { create(:root_task) }
  let(:distribution_task) { create(:distribution_task, parent: root_task) }
  let(:task_class) { SendInitialNotificationLetterTask }
  before do
    cob_team.add_user(user)
    User.authenticate!(user: user)
    FeatureToggle.enable!(:cc_appeal_workflow)
  end

  describe ".verify_user_can_create" do
    let(:params) { { appeal: root_task.appeal, parent_id: distribution_task_id, type: task_class.name } }
    let(:distribution_task_id) { distribution_task.id }

    context "when no distribution_task exists for appeal" do
      let(:distribution_task_id) { nil }

      it "throws an error" do
        expect { task_class.create_from_params(params, user) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    # test contexts for successfully creating task when an appeal has a CC will go here once other tasks are made
  end

  describe ".available_actions" do
    let(:send_initial_notification_letter_task) { task_class.create!(appeal: distribution_task.appeal, parent_id: distribution_task.id, assigned_to: cob_team) }

    let(:available_task_actions) do
      [
        Constants.TASK_ACTIONS.MARK_TASK_AS_COMPLETE_CONTESTED_CLAIM.to_h,
        Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER_CC.to_h,
        Constants.TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_INITIAL_LETTER_TASK.to_h
      ]
    end

    context "the user is not a member of COB" do
      let(:non_cob_user) { create(:user) }

      subject { send_initial_notification_letter_task.available_actions(non_cob_user) }

      it "returns no actions" do
        expect(subject).to_not eql(available_task_actions)
        expect(subject).to eql([])
      end
    end

    context "the user is a member of COB" do
      subject { send_initial_notification_letter_task.available_actions(user) }

      it "returns the task actions" do
        expect(subject).to eql(available_task_actions)
      end
    end
  end
end
