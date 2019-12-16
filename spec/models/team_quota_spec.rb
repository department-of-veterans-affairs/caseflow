# frozen_string_literal: true

class FakeTask < Dispatch::Task
end

class OtherFakeTask < Dispatch::Task
  def self.completed_on(_date)
    []
  end
end

describe TeamQuota, :postgres do
  before do
    allow(FakeTask).to receive(:completed_on).with(Time.zone.today).and_return(tasks_completed_today)
    allow(FakeTask).to receive(:to_complete).and_return(tasks_to_complete)
  end

  let(:team_quota) { TeamQuota.new(date: Time.zone.today, task_type: FakeTask, user_count: user_count) }
  let(:tasks_completed_today) { [] }
  let(:tasks_to_complete) { [] }
  let(:user_count) { 0 }
  let(:user_quota) { team_quota.assigned_quotas.build(user: user) }
  let(:user) { Generators::User.create }

  context "#task_count_for" do
    before { team_quota.save! }

    subject { team_quota.task_count_for(quota) }

    let(:tasks_completed_today) { [FakeTask.new] * 7 }
    let(:user_count) { 2 }
    let!(:first_quota) { team_quota.assigned_quotas.create(user: Generators::User.create) }
    let!(:second_quota) { team_quota.assigned_quotas.create(user: Generators::User.create) }

    context "when assigned task warrants a remainder" do
      let(:quota) { first_quota }
      it { is_expected.to eq(4) }
    end

    context "when assigned task needs no remainder" do
      let(:quota) { second_quota }
      it { is_expected.to eq(3) }
    end

    context "when there are locked quotas" do
      before { first_quota.update!(locked_task_count: 5) }

      let!(:third_quota) { team_quota.assigned_quotas.create(user: Generators::User.create) }
      let(:user_count) { 3 }

      let(:quota) { second_quota }

      it { is_expected.to eq(1) }
    end

    context "when user_quota isn't part of the team_quota" do
      let(:quota) { UserQuota.new(team_quota_id: 123) }

      it "raises TeamQuota::MismatchedTeamQuota" do
        expect { subject }.to raise_error(TeamQuota::MismatchedTeamQuota)
      end
    end
  end

  context "#tasks_to_assign" do
    before { team_quota.save! }

    subject { team_quota.tasks_to_assign }
    let(:tasks_completed_today) { [FakeTask.new] * 9 }

    context "is the number of tasks" do
      it { is_expected.to eq(9) }
    end

    context "subtracts the number of locked assigned cases" do
      let!(:quota) do
        team_quota.assigned_quotas.create(user: Generators::User.create, locked_task_count: 7)
      end

      it { is_expected.to eq(2) }
    end
  end

  context "#user_quotas" do
    before { team_quota.save! }

    subject { team_quota.user_quotas }
    let(:user_count) { 2 }
    let(:tasks_completed_today) { [FakeTask.new] * 5 }

    context "when there are no assigned quotas" do
      it "returns unassigned quotas" do
        expect(subject.length).to eq(2)
        expect(subject.first).to have_attributes(task_count: 3, user_id: nil, team_quota_id: team_quota.id)
        expect(subject.last).to have_attributes(task_count: 2, user_id: nil, team_quota_id: team_quota.id)
      end
    end

    context "when there are fewer assigned quotas than the user count" do
      before { user_quota.save! }
      let(:user_count) { 3 }

      it "returns both, with the assigned quotas first" do
        expect(subject.length).to eq(3)

        expect(subject.first).to have_attributes(task_count: 2, user_id: user.id, team_quota_id: team_quota.id)
        expect(subject.second).to have_attributes(task_count: 2, user_id: nil, team_quota_id: team_quota.id)
        expect(subject.last).to have_attributes(task_count: 1, user_id: nil, team_quota_id: team_quota.id)
      end
    end

    context "when there are the same assigned_quotas as user count" do
      before { user_quota.save! }
      let(:user_count) { 1 }

      it "returns no unassigned quotas" do
        expect(subject.length).to eq(1)
        expect(subject.first).to have_attributes(task_count: 5, user_id: user.id, team_quota_id: team_quota.id)
      end
    end
  end

  context "#save!" do
    subject { team_quota.save! }

    context "when user count is not set" do
      let(:user_count) { nil }

      context "when no recent quotas" do
        it "does sets user_count to most recent quota" do
          subject
          expect(team_quota.user_count).to eq(TeamQuota::DEFAULT_USER_COUNT)
        end
      end

      context "when there are recent quotas" do
        # Make sure having another task recent quota doesn't interfere
        let!(:another_task_recent_quota) do
          TeamQuota.new(date: Time.zone.today - 1.day, task_type: OtherFakeTask, user_count: 5)
        end

        let!(:recent_quota) { TeamQuota.create!(date: Time.zone.today - 3.days, task_type: "FakeTask", user_count: 3) }

        it "does sets user_count to most recent quota" do
          subject
          expect(team_quota.user_count).to eq(3)
        end
      end
    end

    context "when there are fewer or equal assigned quotas than the user count" do
      let(:user_count) { 23 }

      # Make sure having a recent quota doesn't interfere
      let!(:recent_quota) { TeamQuota.create!(date: Time.zone.today - 3.days, task_type: "FakeTask", user_count: 3) }

      it "does not adjust user_count" do
        subject
        expect(team_quota.user_count).to eq(23)
      end
    end

    context "when there are the more assigned_quotas as user count" do
      before do
        team_quota.save!
        user_quota.save! # Add an assigned_quota to bring the count to 1
      end
      let(:user_count) { 0 }

      it "returns no unassigned quotas" do
        subject
        expect(team_quota.user_count).to eq(1)
      end
    end
  end
end
