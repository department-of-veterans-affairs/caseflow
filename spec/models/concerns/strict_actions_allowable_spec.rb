# frozen_string_literal: true

describe StrictActionsAllowable do
  class AlwaysAllowableTask < Task
    def actions_allowable?(_user)
      true
    end

    def available_actions(_user)
      [Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.to_h]
    end
  end

  class TestTask < AlwaysAllowableTask
    prepend StrictActionsAllowable
  end

  let!(:user) { create(:user) }
  let(:task_status) { Constants.TASK_STATUSES.assigned }

  context "the task is assigned to an organization" do
    let(:organization) { create(:organization) }
    let!(:task) { TestTask.new(assigned_to: organization, status: task_status) }

    context "the user is not an admin in the organization" do
      before { organization.add_user(user) }

      it "does not allow actions" do
        expect_any_instance_of(AlwaysAllowableTask).to_not receive(:actions_allowable?)
        expect(task.actions_allowable?(user)).to eq false
        expect(task.available_actions_unwrapper(user)).to eq []
      end
    end

    context "the user is an admin in the organization" do
      before { OrganizationsUser.make_user_admin(user, organization) }

      it "allows actions" do
        expect_any_instance_of(AlwaysAllowableTask).to receive(:actions_allowable?).twice.and_return(true)
        expect(task.actions_allowable?(user)).to eq true
        expect(task.available_actions_unwrapper(user)).to eq [Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.to_h]
      end
    end
  end

  context "the task is assigned to a user" do
    let!(:task) { TestTask.new(assigned_to: user, status: task_status) }

    it "allows actions" do
      expect_any_instance_of(AlwaysAllowableTask).to receive(:actions_allowable?).twice.and_return(true)
      expect(task.actions_allowable?(user)).to eq true
      expect(task.available_actions_unwrapper(user)).to eq [Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.to_h]
    end
  end

  context "the task is assigned to a different user" do
    let!(:other_user) { create(:user) }
    let!(:task) { TestTask.new(assigned_to: other_user, status: task_status) }

    it "does not allow actions" do
      expect_any_instance_of(AlwaysAllowableTask).to_not receive(:actions_allowable?)
      expect(task.actions_allowable?(user)).to eq false
      expect(task.available_actions_unwrapper(user)).to eq []
    end
  end
end
