require "rails_helper"

class FakeTask < Task
  before_create do
    # Automatically set appeal to make test data setup easier
    self.appeal ||= Generators::Appeal.create
  end
end

describe UserQuota do
  let(:team_quota) { TeamQuota.create!(date: Time.zone.today, task_type: FakeTask, user_count: 1) }
  let(:user) { Generators::User.create(full_name: "Sammy Davis Jr") }
  let(:other_user) { User.create(station_id: "ABC", css_id: "JANEY", full_name: "Jane Doe") }
  let(:user_quota) { UserQuota.new(team_quota: team_quota, user: user) }

  context ".create!" do
    subject { UserQuota.create!(team_quota: team_quota, user: user) }
    before { team_quota.save! }

    it "saves associated team quota" do
      team_quota.user_count = 15
      subject
      expect(team_quota.reload.user_count).to eq(15)
    end
  end

  context "#task_count" do
    subject { user_quota.task_count }

    context "when no locked task count" do
      before do
        allow(FakeTask).to receive(:completed_on).with(Time.zone.today).and_return([FakeTask.new] * 3)
        user_quota.save!
      end

      it { is_expected.to eq(3) }
    end

    context "when locked task count" do
      before do
        user_quota.locked_task_count = 30
      end

      it { is_expected.to eq(30) }
    end
  end

  context "#tasks_left_count" do
    subject { user_quota.tasks_left_count }

    before do
      allow(FakeTask).to receive(:completed_on).with(Time.zone.today).and_return([FakeTask.new] * 3)
      allow(user_quota).to receive(:tasks_completed_count).and_return(1)
      user_quota.save!
    end

    it { is_expected.to eq(2) }
  end

  context "#user_name" do
    subject { user_quota.user_name }

    context "when no user" do
      let(:user) { nil }
      it { is_expected.to be_nil }
    end

    context "when user" do
      it { is_expected.to eq("Sammy Davis Jr") }
    end
  end

  context "#tasks_completed_count" do
    subject { user_quota.tasks_completed_count }

    let!(:task_completed_by_other_user) do
      FakeTask.create(aasm_state: :completed, completed_at: Time.zone.now, user: other_user)
    end

    let!(:task_completed_by_user) do
      FakeTask.create(aasm_state: :completed, completed_at: Time.zone.now, user: user)
    end

    let!(:old_task_completed_by_user) do
      FakeTask.create(aasm_state: :completed, completed_at: 25.hours.ago, user: user)
    end

    it { is_expected.to eq(1) }
  end

  context "scopes" do
    let!(:quota_with_locked_task_count) do
      UserQuota.create!(team_quota: team_quota, user: user, locked_task_count: 13)
    end

    let!(:quota_with_automatic_task_count) do
      UserQuota.create!(team_quota: team_quota, user: other_user)
    end

    context ".locked" do
      subject { UserQuota.locked }
      it { is_expected.to eq([quota_with_locked_task_count]) }
    end

    context ".unlocked" do
      subject { UserQuota.unlocked }
      it { is_expected.to eq([quota_with_automatic_task_count]) }
    end
  end
end
