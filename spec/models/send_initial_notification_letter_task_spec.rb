# frozen_string_literal: true

require_relative "./send_notification_shared_examples_spec.rb"

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

  include_examples "verify_user_can_create"

  describe ".available_actions" do
    let(:send_initial_notification_letter_task) do
      task_class.create!(appeal: distribution_task.appeal, parent_id: distribution_task.id, assigned_to: cob_team)
    end

    let(:available_task_actions) do
      [
        Constants.TASK_ACTIONS.MARK_TASK_AS_COMPLETE_CONTESTED_CLAIM.to_h,
        Constants.TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER_INITIAL.to_h,
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
