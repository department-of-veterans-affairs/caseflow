# frozen_string_literal: true

describe EngineeringTask, :postgres do
  let(:sys_admin) { create(:user, roles: ["System Admin"]) }
  before do
    User.authenticate!(user: sys_admin)
  end

  let(:org_admin) { create(:user) { |u| OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton) } }
  let(:other_user) { create(:user) }

  let(:appeal) { create(:appeal, :with_schedule_hearing_tasks) }

  describe ".create" do
    subject { described_class.create(parent: parent_task, appeal: appeal) }
    let(:parent_task) { appeal.root_task }
    let(:parent_task_class) { CavcTask }

    it "creates task" do
      new_task = subject
      expect(new_task.valid?).to eq true
    end

    context "parent is nil" do
      let(:parent_task) { nil }
      it "fails to create task" do
        new_task = subject
        expect(new_task.invalid?).to eq true
        expect(new_task.errors.messages[:parent]).to include("can't be blank")
      end
    end
  end

  describe "#available_actions" do
    let!(:mdr_task) { described_class.create_with_hold(cavc_task) }

    context "immediately after MdrTask is created" do
      it "returns available actions when MdrTask is on hold" do
        expect(mdr_task.reload.status).to eq Constants.TASK_STATUSES.on_hold
        child_timed_hold_tasks = mdr_task.children.of_type(:TimedHoldTask)
        expect(child_timed_hold_tasks.first.status).to eq Constants.TASK_STATUSES.assigned

        expect(mdr_task.available_actions(org_admin)).to include Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
        expect(mdr_task.available_actions(org_nonadmin)).to include Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
        expect(mdr_task.available_actions(other_user)).to be_empty
      end
    end
  end
end
