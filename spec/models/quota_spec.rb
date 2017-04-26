require "rails_helper"

class FakeTask < Task
end

class OtherFakeTask < Task
  def self.completed_today
    []
  end
end

describe Quota do
  before do
    allow(FakeTask).to receive(:completed_today).and_return(tasks_completed_today)
    allow(FakeTask).to receive(:to_complete).and_return(tasks_to_complete)
  end

  let(:quota) { Quota.new(date: Time.zone.today, task_klass: FakeTask) }
  let(:tasks_completed_today) { [] }
  let(:tasks_to_complete) { [] }
  let(:user) { Generators::User.build }

  context "#per_assignee" do
    subject { quota.per_assignee }

    let(:tasks_to_complete) { [1, 2, 3] }
    let(:tasks_completed_today) { [FakeTask.new(user: user)] * 3 }

    context "when there is a remainder" do
      before { quota.update_assignee_count!(4) }
      it { is_expected.to eq(2) }
    end

    context "when tasks divide into assignee account evenly" do
      before { quota.update_assignee_count!(2) }
      it { is_expected.to eq(3) }
    end
  end

  context "#assignee_count" do
    subject { quota.assignee_count }

    # Set quota for another task type to validate they are not loaded
    before { another_task_quota.update_assignee_count!("13") }
    let(:another_task_quota) { Quota.new(date: Time.zone.today, task_klass: OtherFakeTask) }

    context "when no recent quotas" do
      context "when no value is saved" do
        it { is_expected.to eq(Quota::DEFAULT_ASSIGNEE_PROJECTION) }
      end
    end

    context "when there are recent quotas" do
      before { recent_quota.update_assignee_count!(15) }
      let(:recent_quota) { Quota.new(date: Time.zone.today - 3.days, task_klass: FakeTask) }

      context "when no value is saved" do
        it { is_expected.to eq(15) }
      end

      context "when a value is saved" do
        before { quota.update_assignee_count!(23) }
        it { is_expected.to eq(23) }
      end
    end
  end

  context "#recalculate_assignee_count!" do
    subject { quota.recalculate_assignee_count! }

    before { allow(FakeTask).to receive(:completed_today).and_return(tasks_completed_today) }

    # Two completed tasks by just one user
    let(:user) { Generators::User.build }
    let(:tasks_completed_today) { [FakeTask.new(user: user), FakeTask.new(user: user)] }

    context "when active assignees is more than the current assignee count" do
      subject { quota.update_assignee_count!(0) }

      it "updates the assignee_count to the number of active assignees" do
        is_expected.to be_truthy
        expect(quota.assignee_count).to eq(1)
      end
    end

    context "when active assignees is less or equal to than the current assignee count" do
      subject { quota.update_assignee_count!(6) }

      it "does nothing" do
        is_expected.to be_truthy
        expect(quota.assignee_count).to eq(6)
      end
    end
  end

  context "#update_assignee_count!" do
    subject { quota.update_assignee_count!(1) }

    before { allow(FakeTask).to receive(:completed_today).and_return(tasks_completed_today) }

    # Two completed tasks by just one user
    let(:tasks_completed_today) { [FakeTask.new(user: user), FakeTask.new(user: user)] }

    it "updates assignee projection in redis" do
      is_expected.to be_truthy
      expect(quota.assignee_count).to eq(1)

      reloaded_quota = Quota.new(date: Time.zone.today, task_klass: FakeTask)
      expect(reloaded_quota.assignee_count).to eq(1)
    end

    context "when active assignees is more than the projection" do
      # Two completed tasks by two different users
      let(:tasks_completed_today) { [FakeTask.new(user: user), FakeTask.new(user: Generators::User.build)] }

      it "updates the assignee_count to the number of active assignees" do
        is_expected.to be_truthy
        expect(quota.assignee_count).to eq(2)
      end
    end
  end
end
