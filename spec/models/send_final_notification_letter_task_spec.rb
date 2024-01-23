# frozen_string_literal: true

require_relative "./send_notification_shared_examples_spec.rb"

describe SendFinalNotificationLetterTask do
  let(:user) { create(:user) }
  let(:cob_team) { ClerkOfTheBoard.singleton }
  let(:root_task) { create(:root_task) }
  let(:distribution_task) { create(:distribution_task, parent: root_task) }
  let(:task_class) { SendFinalNotificationLetterTask }
  before do
    cob_team.add_user(user)
    User.authenticate!(user: user)
    FeatureToggle.enable!(:cc_appeal_workflow)
  end

  include_examples "verify_user_can_create"

  describe ".available_actions" do
    let(:final_notification_letter_task) {
      task_class.create!(appeal: distribution_task.appeal, parent_id: distribution_task.id, assigned_to: cob_team)
    }

    let(:available_task_actions) do
      [
        Constants.TASK_ACTIONS.MARK_FINAL_NOTIFICATION_LETTER_TASK_COMPLETE.to_h,
        Constants.TASK_ACTIONS.RESEND_INITIAL_NOTIFICATION_LETTER_FINAL.to_h,
        Constants.TASK_ACTIONS.RESEND_FINAL_NOTIFICATION_LETTER.to_h,
        Constants.TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_FINAL_LETTER_TASK.to_h
      ]
    end

    context "the user is not a member of COB" do
      let(:non_cob_user) { create(:user) }

      subject { final_notification_letter_task.available_actions(non_cob_user) }

      it "returns no actions" do
        expect(subject).to_not eql(available_task_actions)
        expect(subject).to eql([])
      end
    end

    context "the user is a member of COB" do
      subject { final_notification_letter_task.available_actions(user) }

      it "returns the task actions" do
        expect(subject).to eql(available_task_actions)
      end
    end
  end

  describe "Mark final notification letter task as complete" do
    let(:user) { create(:user) }
    let(:cob_team) { ClerkOfTheBoard.singleton }
    let(:root_task) { create(:root_task) }
    let(:distribution_task) { create(:distribution_task, parent: root_task) }
    let(:days_on_hold) { 45 }

    let(:initial_letter_task) do
      SendInitialNotificationLetterTask.create!(
        appeal: root_task.appeal,
        parent: distribution_task,
        assigned_to: cob_team
      )
    end

    let(:post_initial_task) do
      PostSendInitialNotificationLetterHoldingTask.create!(
        appeal: distribution_task.appeal,
        parent: distribution_task,
        end_date: Time.zone.now + days_on_hold.days,
        assigned_by: user,
        assigned_to: cob_team,
        instructions: "45 Day Hold Period"
      )
    end
    let(:post_task_timer) do
      TimedHoldTask.create_from_parent(
        post_initial_task,
        days_on_hold: days_on_hold,
        instructions: "45 Days Hold Period"
      )
    end

    let(:final_letter_task) do
      SendFinalNotificationLetterTask.create!(
        appeal: root_task.appeal,
        parent: distribution_task,
        assigned_to: cob_team
      )
    end

    let(:params) { { appeal: root_task.appeal, parent_id: root_task.id, instructions: "foo bar" } }

    subject { DocketSwitchMailTask.create_from_params(params, user) }

    before do
      cob_team.add_user(user)
      User.authenticate!(user: user)
      FeatureToggle.enable!(:cc_appeal_workflow)
    end

    it "Finalice the process, select NO in the radio bottom option" do
      initial_letter_task.completed!
      post_initial_task.completed!
      final_letter_task.completed!

      task_complete = Task.find_by(type: "SendFinalNotificationLetterTask")
      expect(task_complete.appeal_id).to eq(post_initial_task.appeal_id)
      expect(task_complete.status).to eq("completed")
    end

    it "Finalice the process, select Yes in the radio bottom option" do
      initial_letter_task.completed!
      post_initial_task.completed!
      final_letter_task.completed!

      subject
      expect(DocketSwitchMailTask.assigned_to_any_org).to exist
      expect(DocketSwitchMailTask.assigned_to_any_user).to exist
      expect(subject.parent.parent.type).to eq DistributionTask.name
    end
  end
end
