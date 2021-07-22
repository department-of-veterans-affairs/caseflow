# frozen_string_literal: true

describe EngineeringTask, :postgres do
  let(:sys_admin) { create(:user).tap { |user| Functions.grant!("System Admin", users: [user.css_id]) } }
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
      expect(new_task.assigned_to).to eq User.system_user

      expect(new_task.available_actions(sys_admin)).to include Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
      expect(new_task.available_actions(org_admin)).to be_empty
      expect(new_task.available_actions(other_user)).to be_empty
    end

    it "creates task assigned to specific user" do
      new_task = described_class.create!(parent: parent_task, appeal: appeal, assigned_to: sys_admin)
      expect(new_task.valid?).to eq true
      expect(new_task.assigned_to).to eq sys_admin
    end

    context "when appeal is ready for dispatch but engineering work is needed first" do
      let(:appeal) { create(:appeal, :at_bva_dispatch) }
      let(:parent_task) { appeal.tasks.find_by(type: :BvaDispatchTask, assigned_to_type: "User") }

      it "blocks parent BvaDispatchTask" do
        new_task = subject
        expect(parent_task.status).to eq "on_hold"
        expect(new_task.status).to eq "assigned"
      end
    end

    context "parent is not provided" do
      let(:parent_task) { nil }
      it "fails to create task" do
        new_task = subject
        expect(new_task.invalid?).to eq true
        expect(new_task.errors.messages[:parent]).to include("can't be blank")
      end
    end
  end

  let(:task) { described_class.create(parent: parent_task, appeal: appeal) }
  describe "#append_instruction" do
    it "appends new instruction to task" do
      task.append_instruction("first instruction")
      expect(task.instructions).to eq ["first instruction"]
      task.append_instruction("second instruction")
      expect(task.instructions).to eq ["first instruction", "second instruction"]
    end
  end

  describe "#reassign" do
    subject { task.reassign(new_assignee) }

    let(:appeal) { create(:appeal, :at_bva_dispatch) }
    let(:parent_task) { appeal.tasks.find_by(type: :BvaDispatchTask, assigned_to_type: "User") }
    let(:new_assignee) { create(:user) }

    it "cancels original task and reassigns a new task to specified user" do
      expect(task.status).to eq "assigned"
      expect(task.assigned_to).to eq User.system_user
      reassigned_task = subject
      expect(task.status).to eq "cancelled"
      expect(task.assigned_to).to eq User.system_user
      expect(reassigned_task.status).to eq "assigned"
      expect(reassigned_task.assigned_to).to eq new_assignee

      task.append_instruction("reassigned to #{new_assignee.css_id}")
      expect(task.instructions).to eq ["reassigned to #{new_assignee.css_id}"]
    end

    context "task is closed" do
      before { task.cancelled! }
      it "fails reassignment" do
        expect { subject }.to raise_error(/Cannot reassign/)
      end
    end
  end

  describe "#create_timed_hold_task" do
    let(:days_on_hold) { 30 }
    subject { task.create_timed_hold_task(days_on_hold) }

    it "puts EngineeringTask on hold" do
      timed_hold_task = subject
      expect(timed_hold_task.parent).to eq task
      expect(timed_hold_task.parent.status).to eq "on_hold"
      expect(timed_hold_task.status).to eq "assigned"
      expect(timed_hold_task.timer_end_time).to be_within(5.minutes).of(timed_hold_task.created_at + days_on_hold.days)
    end
  end

  describe "when checking for stuck appeals" do
    let(:hearing_task) { appeal.tasks.find_by(type: :HearingTask) }
    let(:schedule_task) { appeal.tasks.find_by(type: :ScheduleHearingTask) }

    before do
      schedule_task.cancelled!
    end

    it "does not cause a false alert from AppealsWithNoTasksOrAllTasksOnHoldQuery" do
      # without EngineeringTask
      stuck_appeals = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      expect(stuck_appeals).to include appeal # false alert

      # with EngineeringTask
      described_class.create(parent: hearing_task, appeal: appeal)
      stuck_appeals2 = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      expect(stuck_appeals2).to be_empty
    end
  end
end
