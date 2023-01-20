# frozen_string_literal: true

require "ostruct"

class FakeTask < Dispatch::Task
  before_create do
    # Automatically set appeal to make test data setup easier
    self.appeal ||= Generators::LegacyAppeal.create
  end

  def should_invalidate?
    appeal.vbms_id == "INVALID"
  end
end

describe Dispatch::Task, :postgres do
  before { Timecop.freeze(Time.utc(2016, 2, 17, 20, 59, 0)) }

  let(:appeal) { Generators::LegacyAppeal.create }
  let(:task) { FakeTask.create(appeal: appeal, aasm_state: aasm_state, user: assigned_user) }
  let(:user) { Generators::User.create(full_name: "Robert Smith") }
  let(:aasm_state) { :unassigned }
  let(:assigned_user) { nil }

  context ".newest_first" do
    subject { Dispatch::Task.newest_first.all }

    let!(:newest_task) { FakeTask.create(created_at: 1.second.ago) }
    let!(:oldest_task) { FakeTask.create(created_at: 2.seconds.ago) }

    it { is_expected.to eq([newest_task, oldest_task]) }
  end

  context ".oldest_first" do
    subject { Dispatch::Task.oldest_first.all }

    let!(:newest_task) { FakeTask.create(created_at: 1.second.ago) }
    let!(:oldest_task) { FakeTask.create(created_at: 2.seconds.ago) }

    it { is_expected.to eq([oldest_task, newest_task]) }
  end

  context ".prepared_before_today" do
    subject { Dispatch::Task.prepared_before_today }
    let!(:task_prepared_yesterday) { FakeTask.create!(aasm_state: :unassigned, prepared_at: Date.yesterday) }
    let!(:task_prepared_today) { FakeTask.create!(aasm_state: :unassigned) }

    it { is_expected.to eq([task_prepared_yesterday]) }
  end

  context ".to_complete" do
    subject { Dispatch::Task.to_complete }

    let!(:unprepared_task) { FakeTask.create!(aasm_state: :unprepared) }
    let!(:completed_task) { FakeTask.create!(aasm_state: :completed) }
    let!(:unassigned_task) { FakeTask.create!(aasm_state: :unassigned, prepared_at: Date.yesterday) }
    let!(:reviewed_task) { FakeTask.create!(aasm_state: :reviewed, prepared_at: Date.yesterday) }

    it { is_expected.to eq([unassigned_task, reviewed_task]) }
  end

  context ".completed_on" do
    subject { FakeTask.completed_on(Time.zone.today).all }

    let!(:task_completed_this_morning) do
      FakeTask.create(aasm_state: :completed, completed_at: Time.zone.now.beginning_of_day)
    end

    let!(:task_completed_tonight) do
      FakeTask.create(aasm_state: :completed, completed_at: Time.zone.now.end_of_day)
    end

    let!(:task_completed_yesterday) do
      FakeTask.create(aasm_state: :completed, completed_at: Time.zone.now.end_of_day - 1.day)
    end

    let!(:task_not_completed) do
      FakeTask.create(aasm_state: :reviewed, completed_at: Time.zone.now)
    end

    # .sort added in case ActiveRecord returns tasks out of order in subject
    it { is_expected.to eq([task_completed_this_morning, task_completed_tonight].sort) }
  end

  context ".completed_success" do
    subject { Dispatch::Task.completed_success }

    let!(:successful_task) { FakeTask.create!(completion_status: :routed_to_arc) }
    let!(:canceled_task) { FakeTask.create!(completion_status: :canceled) }

    it "returns only the successfully completed task" do
      is_expected.to eq [successful_task]
    end
  end

  context "#assigned_not_completed" do
    subject { Dispatch::Task.assigned_not_completed }

    let!(:unassigned_task) { FakeTask.create!(prepared_at: Date.yesterday) }
    let!(:assigned_task) do
      FakeTask.create!(
        assigned_at: Time.zone.now,
        prepared_at: Date.yesterday,
        aasm_state: :assigned
      )
    end
    let!(:completed_task) do
      FakeTask.create!(
        assigned_at: Time.zone.now,
        prepared_at: Date.yesterday,
        aasm_state: :completed
      )
    end

    it { is_expected.to eq([assigned_task]) }
  end

  context "#progress_status" do
    subject { task.progress_status }

    context "when unprepared" do
      let(:aasm_state) { :unprepared }
      it { is_expected.to eq("Unassigned") }
    end

    context "when assigned" do
      let(:aasm_state) { :assigned }
      it { is_expected.to eq("Not Started") }
    end

    context "when started" do
      let(:aasm_state) { :started }
      it { is_expected.to eq("In Progress") }
    end

    context "task is completed" do
      let(:aasm_state) { :completed }
      it { is_expected.to eq("Completed") }
    end
  end

  context "#start!" do
    subject { task.start! }

    context "when assigned" do
      let(:aasm_state) { :assigned }
      let(:assigned_user) { user }

      it "is successful, sets started_at, and creates a new user quota" do
        is_expected.to be_truthy
        expect(task.reload.started_at).to eq(Time.zone.now)

        expect(FakeTask.todays_quota.assigned_quotas.find_by(user: user)).to_not be_nil
      end

      context "when a quota already exists" do
        let!(:user_quota) { FakeTask.todays_quota.assigned_quotas.create!(user: user) }

        it "doesn't create new quota" do
          is_expected.to be_truthy
          expect(FakeTask.todays_quota.assigned_quotas.where(user: user).count).to eq(1)
        end
      end
    end

    context "when not assigned" do
      it "raises InvalidTransition" do
        expect { subject }.to raise_error(AASM::InvalidTransition)
      end
    end
  end

  context "#prepare!" do
    subject { task.prepare! }

    context "when unprepared" do
      let(:aasm_state) { :unprepared }

      it "prepared_at should be nil" do
        expect(task.prepared_at).to be_nil
      end

      it "sets prepared_at" do
        task.prepare!
        expect(task.reload.prepared_at).to eq(Time.zone.now)
      end
    end

    context "when already prepared" do
      let(:aasm_state) { :unassigned }

      it "raises InvalidTransition" do
        expect { subject }.to raise_error(AASM::InvalidTransition)
      end
    end
  end

  context "#complete!" do
    subject { task.complete!(params) }
    let(:params) { { status: :routed_to_ro, outgoing_reference_id: "123WOO" } }
    let(:assigned_user) { user }

    context "when in a non-completable state" do
      let(:aasm_state) { :unassigned }

      it "raises error and doesn't save completion_status" do
        expect { subject }.to raise_error(AASM::InvalidTransition)

        expect(task.reload.completed_at).to be_nil
        expect(task.completion_status).to be_nil
      end
    end

    context "when started" do
      let(:aasm_state) { :started }

      it "completes the task with outgoing_reference_id" do
        subject

        expect(task.reload).to have_attributes(
          completed_at: Time.zone.now,
          completion_status: "routed_to_ro",
          outgoing_reference_id: "123WOO"
        )
      end
    end

    context "when reviewed" do
      let(:aasm_state) { :reviewed }

      it "completes the task without outgoing_reference_id and creates a quota" do
        subject

        expect(task.reload).to have_attributes(
          completed_at: Time.zone.now,
          completion_status: "routed_to_ro",
          outgoing_reference_id: nil
        )

        expect(FakeTask.todays_quota.assigned_quotas.find_by(user: user)).to_not be_nil
      end
    end

    context "when completed" do
      let(:aasm_state) { :completed }

      it "raises error and doesn't save completion_status" do
        expect { subject }.to raise_error(AASM::InvalidTransition)

        expect(task.reload.completed_at).to be_nil
        expect(task.completion_status).to be_nil
      end
    end
  end

  context "#expire!" do
    subject { task.expire! }
    let(:assigned_user) { user }
    let(:aasm_state) { :started }

    it "sets status to completed and completion_status to expired" do
      is_expected.to be_truthy

      expect(task.reload).to be_completed
      expect(task).to be_expired
    end

    it "recreates a new unprepared task" do
      subject
      expect(FakeTask.where(aasm_state: :unprepared, appeal: task.appeal).length).to eq(1)
    end

    context "when new task creation fails" do
      before do
        allow(FakeTask).to receive(:create!).and_raise("Roar")
      end

      it "rolls back state change too" do
        expect { subject }.to raise_error("Roar")
        expect(task.reload).to_not be_completed
        expect(task).to_not be_expired
      end
    end
  end

  context "#cancel!" do
    subject { task.cancel!("feedbackz") }

    let(:aasm_state) { :started }
    let(:assigned_user) { user }

    it "sets task to cancelled and saves feedback" do
      is_expected.to be_truthy

      expect(task.reload).to be_completed
      expect(task).to be_canceled
      expect(task.reload.comment).to eq("feedbackz")
    end
  end

  context "#days_since_creation" do
    subject { task.days_since_creation }

    let(:task) { FakeTask.create!(created_at: 7.days.ago) }

    it "returns the correct number of days" do
      is_expected.to eq(7)
    end
  end

  context "#should_assign?" do
    subject { task.should_assign? }

    it { is_expected.to be_truthy }

    context "if task is invalid" do
      let(:appeal) { Generators::LegacyAppeal.create(vbms_id: "INVALID") }

      it "invalidates the task and returns false" do
        is_expected.to be_falsey
        expect(task.reload).to be_invalidated
      end
    end

    context "if task isn't accessible by the logged in user" do
      let(:appeal) { Generators::LegacyAppeal.create(inaccessible: true) }
      it { is_expected.to be_falsey }
    end
  end

  context ".any_assignable_to?" do
    subject { FakeTask.any_assignable_to?(user) }

    context "when user already has an assigned task" do
      let!(:assigned_task) do
        FakeTask.create!(
          aasm_state: :started,
          user: user,
          prepared_at: Date.yesterday,
          appeal: Generators::LegacyAppeal.create
        )
      end

      it { is_expected.to eq(true) }
    end

    context "when there are assignable tasks" do
      let!(:next_assignable_task) do
        FakeTask.create!(aasm_state: :unassigned, appeal: Generators::LegacyAppeal.create)
      end

      it { is_expected.to eq(true) }
    end

    context "when there are no assignable tasks" do
      let!(:completed_task) do
        FakeTask.create!(aasm_state: :completed, appeal: Generators::LegacyAppeal.create)
      end

      it { is_expected.to eq(false) }
    end

    context "when there is an invalid task" do
      let!(:invalid_task) do
        FakeTask.create!(
          appeal: Generators::LegacyAppeal.create(vbms_id: "INVALID"),
          aasm_state: :unassigned
        )
      end

      it "invalidates that task and returns false" do
        is_expected.to eq(false)

        expect(invalid_task.reload).to have_attributes(
          aasm_state: "completed",
          user_id: nil,
          completion_status: "invalidated"
        )
      end
    end
  end

  context ".assign_next_to!" do
    subject { FakeTask.assign_next_to!(user) }

    context "when user already has an assigned task" do
      let!(:assigned_task) do
        FakeTask.create!(
          aasm_state: :reviewed,
          prepared_at: Date.yesterday,
          created_at: 40.seconds.ago,
          user: user,
          appeal: Generators::LegacyAppeal.create
        )
      end

      let!(:next_assignable_task) do
        FakeTask.create!(
          aasm_state: :unassigned,
          created_at: 39.seconds.ago,
          prepared_at: Date.yesterday,
          appeal: Generators::LegacyAppeal.create
        )
      end

      it "does nothing and returns the assigned task" do
        is_expected.to eq(assigned_task)

        expect(next_assignable_task.reload).to have_attributes(
          aasm_state: "unassigned",
          user_id: nil
        )
      end
    end

    context "when user does not have an assigned task" do
      let!(:inaccessible_task) do
        FakeTask.create!(
          aasm_state: :unassigned,
          created_at: 35.seconds.ago,
          appeal: Generators::LegacyAppeal.create(inaccessible: true)
        )
      end

      let!(:completed_task) do
        FakeTask.create!(
          aasm_state: :completed,
          created_at: 34.seconds.ago,
          appeal: Generators::LegacyAppeal.create
        )
      end

      let!(:unprepared_task) do
        FakeTask.create!(
          aasm_state: :unprepared,
          created_at: 33.seconds.ago,
          appeal: Generators::LegacyAppeal.create
        )
      end

      context "when there are assignable tasks" do
        let!(:after_next_assignable_task) do
          FakeTask.create!(
            aasm_state: :unassigned,
            created_at: 31.seconds.ago,
            appeal: Generators::LegacyAppeal.create
          )
        end

        let!(:next_assignable_task) do
          FakeTask.create!(
            aasm_state: :unassigned,
            created_at: 32.seconds.ago,
            appeal: Generators::LegacyAppeal.create
          )
        end

        it "assigns only the next assignable task" do
          is_expected.to_not be_nil

          expect(unprepared_task.reload).to have_attributes(user_id: nil)
          expect(completed_task.reload).to have_attributes(user_id: nil)
          expect(inaccessible_task.reload).to have_attributes(user_id: nil)

          expect(after_next_assignable_task.reload).to have_attributes(
            aasm_state: "unassigned",
            user_id: nil
          )

          expect(subject).to eq(next_assignable_task)
        end

        context "when there is a race condition in assigning a task" do
          before do
            allow_any_instance_of(FakeTask).to receive(:before_should_assign) do
              Dispatch::Task.find(next_assignable_task.id)
                .update!(comment: "force lock_version to increment")
            end
          end

          it "retries and assigns the next task" do
            subject
            expect(next_assignable_task.reload).to have_attributes(
              aasm_state: "assigned",
              user_id: user.id
            )
          end
        end
      end

      context "when there are no assignable tasks" do
        it "does not assign a task and returns nil" do
          is_expected.to be_nil

          expect(FakeTask.find_by(user: user)).to be_nil
        end

        context "when there is an invalid task" do
          let!(:invalid_task) do
            FakeTask.create!(
              created_at: 40.seconds.ago,
              appeal: Generators::LegacyAppeal.create(vbms_id: "INVALID"),
              aasm_state: :unassigned
            )
          end

          it "invalidates that task and assigns the next task" do
            is_expected.to be_nil

            expect(invalid_task.reload).to have_attributes(
              aasm_state: "completed",
              user_id: nil,
              completion_status: "invalidated"
            )
          end
        end
      end
    end
  end

  context ".completed_by" do
    subject { FakeTask.completed_by(user) }

    let(:other_user) { User.create(station_id: "ABC", css_id: "JANEY", full_name: "Jane Doe") }

    let!(:incomplete_task) do
      FakeTask.create(user: user, appeal: appeal)
    end

    let!(:task_completed_by_other_user) do
      FakeTask.create(aasm_state: :completed, user: other_user, appeal: appeal)
    end

    let!(:task_completed_by_user) do
      FakeTask.create(aasm_state: :completed, user: user, appeal: appeal)
    end

    it { is_expected.to eq([task_completed_by_user]) }
  end

  context "#completion_status_text" do
    subject { task.completion_status_text }
    let(:task) { FakeTask.new(completion_status: completion_status) }

    context "when completion_status is nil" do
      let(:completion_status) { nil }
      it { is_expected.to eq("") }
    end

    context "when completion_status does not have special text" do
      let(:completion_status) { :special_issue_emailed }
      it { is_expected.to eq("Special Issue Emailed") }
    end

    context "when completion_status has special text" do
      let(:completion_status) { :assigned_existing_ep }
      it { is_expected.to eq("Assigned Existing EP") }
    end
  end

  context ".todays_quota" do
    subject { FakeTask.todays_quota }

    context "when team_quota already exists for task today" do
      let!(:team_quota) { TeamQuota.create!(task_type: FakeTask, date: Time.zone.today) }
      it { is_expected.to eq(team_quota) }
    end

    context "when no team_quota exists for task today" do
      let!(:old_team_quota) { TeamQuota.create!(task_type: FakeTask, date: Time.zone.yesterday) }
      it { is_expected.to have_attributes(date: Time.zone.today, task_type: "FakeTask") }
    end
  end
end
