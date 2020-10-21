# frozen_string_literal: true

describe DocketSwitchMailTask, :postgres do
  let(:user) { create(:user) }
  let(:cotb_team) { ClerkOfTheBoard.singleton }
  let(:root_task) { create(:root_task) }
  let(:task_class) { DocketSwitchDeniedTask }

  let(:task_actions) do
    [
      Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
      Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
      Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
      Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
      Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
      Constants.TASK_ACTIONS.CANCEL_TASK.to_h
    ]
  end

  before do
    cotb_team.add_user(user)
  end

  fdescribe ".available_actions" do
    let(:attorney_task) { task_class.create!(appeal: root_task.appeal, parent_id: root_task.id, assigned_to: user) }

    subject { attorney_task.available_actions(user) }

    context "when the current user is not a member of the Clerk of the Board team" do
      before { allow_any_instance_of(ClerkOfTheBoard).to receive(:user_has_access?).and_return(false) }

      context "without docket_change feature toggle" do
        it "returns the available_actions as defined by Task" do
          binding.pry
          expect(subject).to eq(task_actions)
        end
      end

      context "with docket_change feature toggle" do
        before { FeatureToggle.enable!(:docket_change) }
        after { FeatureToggle.disable!(:docket_change) }

        it "returns the available_actions as defined by Task" do
          expect(subject).to eq(task_actions)
        end
      end
    end

    context "when the current user is a member of the Clerk of the Board team" do
      context "without docket_change feature toggle" do
        it "returns the available_actions as defined by Task" do
          expect(subject).to eq(task_actions)
        end
      end

      context "with docket_change feature toggle" do
        before { FeatureToggle.enable!(:docket_change) }
        after { FeatureToggle.disable!(:docket_change) }

        it "returns the available_actions as defined by Task" do
          expect(subject).to eq(task_actions + [Constants.TASK_ACTIONS.DOCKET_SWITCH_DENIED.to_h])
        end
      end
    end
  end
end
