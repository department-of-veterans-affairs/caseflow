# frozen_string_literal: true

describe DocketSwitchMailTask, :postgres do
  let(:user) { create(:user) }
  let(:judge) { create(:user, :judge) }
  let(:cotb_team) { ClerkOfTheBoard.singleton }
  let(:root_task) { create(:root_task) }
  let(:task_class) { DocketSwitchMailTask }
  let(:distribution_task) { create(:distribution_task, :completed, appeal: appeal) }
  let(:appeal) { create(:appeal) }

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

      context "without docket_switch feature toggle" do
        it "returns no task actions" do
          expect(subject).to be_empty
        end
      end

      context "with docket_switch feature toggle" do
        before { FeatureToggle.enable!(:docket_switch) }
        after { FeatureToggle.disable!(:docket_switch) }

        it "returns no task actions" do
          expect(subject).to be_empty
        end
      end
    end

    context "when the current user is a member of the Clerk of the Board team" do
      context "without docket_switch feature toggle" do
        it "returns the available_actions as defined by Task" do
          expect(subject).to eq(task_actions)
        end
      end

      context "with docket_switch feature toggle" do
        before { FeatureToggle.enable!(:docket_switch) }
        after { FeatureToggle.disable!(:docket_switch) }

        it "returns the available_actions as defined by Task" do
          expect(subject).to eq(task_actions + [Constants.TASK_ACTIONS.DOCKET_SWITCH_SEND_TO_JUDGE.to_h])
        end
      end
    end
  end

  describe ".create_from_params" do
    before { FeatureToggle.enable!(:docket_switch) }
    after { FeatureToggle.disable!(:docket_switch) }

    context "appeal has been distributed to a VLJ" do
      let(:root_task_on_distributed_appeal) { create(:root_task, appeal: appeal) }
      let!(:judge_assign_task) do
        create(:ama_judge_assign_task,
          assigned_to: judge,
          assigned_at: Time.zone.yesterday,
          appeal: appeal,
          parent: root_task_on_distributed_appeal
        )
      end
      let(:params) { { appeal: appeal, parent_id: root_task_on_distributed_appeal.id, instructions: "foo bar" } }
      subject { DocketSwitchMailTask.create_from_params(params, user) }

      before { RequestStore[:current_user] = user }

      it "creates both org task and user task as children of the RootTask" do
        expect(DocketSwitchMailTask.all.size).to eq(0)
        subject
        expect(DocketSwitchMailTask.assigned_to_any_org).to exist
        expect(DocketSwitchMailTask.assigned_to_any_user).to exist
        expect(subject.parent.parent.type).to eq RootTask.name
      end
    end

    context "appeal has not been distributed to a VLJ" do
      let!(:distribution_task) { create(:distribution_task, :assigned, appeal: root_task.appeal) }
      let(:params) { { appeal: root_task.appeal, parent_id: root_task.id, instructions: "foo bar" } }

      subject { DocketSwitchMailTask.create_from_params(params, user) }

      before { RequestStore[:current_user] = user }

      it "creates both org task and user task as children of the DistributionTask" do
        expect(DocketSwitchMailTask.all.size).to eq(0)
        subject
        expect(DocketSwitchMailTask.assigned_to_any_org).to exist
        expect(DocketSwitchMailTask.assigned_to_any_user).to exist
        expect(subject.parent.parent.type).to eq DistributionTask.name
      end
    end
  end

  describe ".allow_creation?" do
    let(:appeal) { create(:appeal) }
    subject { DocketSwitchMailTask.allow_creation?(user: user, appeal: appeal) }

    context "user is part of Clerk of the Board org" do
      it "allows task creation" do
        expect(subject).to eq(true)
      end

      context "appeal has not been dispatched" do
        it "allows task creation" do
          expect(subject).to eq(true)
        end
      end
    end

    context "user is not part of Clerk of the Board org" do
      before { allow_any_instance_of(ClerkOfTheBoard).to receive(:user_has_access?).and_return(false) }

      it "disallows task creation" do
        expect(subject).to eq(false)
      end
    end

    context "appeal has been dispatched" do
      let(:dispatched_appeal) { create(:appeal, :dispatched) }
      subject { DocketSwitchMailTask.allow_creation?(user: user, appeal: dispatched_appeal) }

      it "disallows task creation" do
        expect(subject).to eq(false)
      end
    end
  end

  describe ".child_task_assignee" do
    let(:org_task) do
      task_class.create!(
        appeal: root_task.appeal, parent_id: distribution_task.id, assigned_to: cotb_team
      )
    end
    let(:parent) { distribution_task }
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
