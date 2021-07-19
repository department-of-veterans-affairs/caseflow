# frozen_string_literal: true

describe EngineeringTask, :postgres do
  let(:sys_admin) { create(:user).tap {|user| Functions.grant!("System Admin", users: [user.css_id])} }
  before do
    User.authenticate!(user: sys_admin)
  end

  let(:org_admin) { create(:user) { |u| OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton) } }
  let(:other_user) { create(:user) }

  let(:appeal) { create(:appeal, :with_schedule_hearing_tasks) }
  let(:parent_task) { appeal.root_task }

  describe ".create" do
    subject { described_class.create(parent: parent_task, appeal: appeal) }

    it "creates task with available_actions" do
      new_task = subject
      expect(new_task.valid?).to eq true
      expect(new_task.available_actions(sys_admin)).to include Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
      expect(new_task.available_actions(org_admin)).to be_empty
      expect(new_task.available_actions(other_user)).to be_empty
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

  describe ".create_timed_hold_task" do
    let(:task) { described_class.create(parent: parent_task, appeal: appeal) }
    let(:days_on_hold) {30}
    subject { task.create_timed_hold_task(days_on_hold) }
    it "puts EngineeringTask on hold" do
      timed_hold_task = subject
      expect(timed_hold_task.parent).to eq task
      expect(timed_hold_task.parent.status).to eq "on_hold"
      expect(timed_hold_task.status).to eq "assigned"
      expect(timed_hold_task.timer_end_time).to eq (timed_hold_task.created_at + days_on_hold.days)
    end
  end
end
