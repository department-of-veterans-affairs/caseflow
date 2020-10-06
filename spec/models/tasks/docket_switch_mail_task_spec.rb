# frozen_string_literal: true

describe DocketSwitchMailTask, :postgres do
  let(:user) { create(:user) }
  let(:cotb_team) { ClerkOfTheBoard.singleton }
  let(:root_task) { create(:root_task) }
  let(:task_class) { DocketSwitchMailTask }

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

  describe ".available_actions" do
    let(:mail_task) { task_class.create!(appeal: root_task.appeal, parent_id: root_task.id, assigned_to: user) }

    subject { mail_task.available_actions(user) }

    context "when the current user is not a member of the Clerk of the Board team" do
      before { allow_any_instance_of(ClerkOfTheBoard).to receive(:user_has_access?).and_return(false) }

      context "without docket_change feature toggle" do
        it "returns the available_actions as defined by Task" do
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
          expect(subject).to eq(task_actions + [Constants.TASK_ACTIONS.DOCKET_CHANGE_SEND_TO_JUDGE.to_h])
        end
      end
    end
  end

  describe ".create_from_params" do
    let(:params) { { parent_id: root_task.id, instructions: "foo bar" } }

    subject { DocketSwitchMailTask.create_from_params(params, user) }

    before { RequestStore[:current_user] = user }

    it "creates both org task and user task" do
      expect(DocketSwitchMailTask.all.size).to eq(0)
      subject
      expect(DocketSwitchMailTask.where(assigned_to_type: "Organization")).to exist
      expect(DocketSwitchMailTask.where(assigned_to_type: "User")).to exist
    end
  end

  describe ".allow_creation?" do
    subject { DocketSwitchMailTask.allow_creation?(user) }

    context "user is part of Clerk of the Board org" do
      it "allows task creation" do
        expect(subject).to eq(true)
      end
    end

    context "user is not part of Clerk of the Board org" do
      before { allow_any_instance_of(ClerkOfTheBoard).to receive(:user_has_access?).and_return(false) }

      it "disallows task creation" do
        expect(subject).to eq(false)
      end
    end
  end

  describe ".child_task_assignee" do
    let(:org_task) { task_class.create!(appeal: root_task.appeal, parent_id: root_task.id, assigned_to: cotb_team) }
    let(:parent) { root_task }
    let(:params) { { parent_id: parent.id } }

    subject { DocketSwitchMailTask.child_task_assignee(parent, params) }

    context "when assigned_to is specified" do
      let(:assigned_to) { create(:user) }
      let(:params) { { **super(), assigned_to_type: User.name, assigned_to_id: assigned_to.id } }

      it "assigns task to specified user" do
        expect(subject).to eq(assigned_to)
      end
    end

    context "when assigned_to not specified, but assigned_by user is available" do
      before { RequestStore[:current_user] = user }

      context "when parent is root task" do
        it "creates org task" do
          expect(subject).to eq(ClerkOfTheBoard.singleton)
        end
      end

      context "when parent is org task" do
        let(:parent) { org_task }

        it "assigns task to the user that created it" do
          expect(subject).to eq(user)
        end
      end
    end
  end
end
