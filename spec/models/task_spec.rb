require "rails_helper"
require "ostruct"

class FakeTask < Task
  def should_invalidate?
    appeal.vbms_id == "INVALID"
  end
end

describe Task do
  # Clear the task from the DB before every test
  before do
    @one_week_ago = Time.utc(2016, 2, 17, 20, 59, 0) - 7.days
    Timecop.freeze(Time.utc(2016, 2, 17, 20, 59, 0))

    @user = User.create(station_id: "ABC", css_id: "123", full_name: "Robert Smith")
    @user2 = User.create(station_id: "ABC", css_id: "456", full_name: "Jane Doe")
  end

  let(:appeal) { Generators::Appeal.create }
  let(:task) { FakeTask.create(appeal: appeal, aasm_state: aasm_state) }
  let(:user) { User.create(station_id: "ABC", css_id: "ROBBY", full_name: "Robert Smith") }
  let(:aasm_state) { :unassigned }

  context ".newest_first" do
    let!(:appeal1) { Appeal.create(vacols_id: "123C") }
    let!(:task1) { EstablishClaim.create(appeal: appeal1) }
    let!(:appeal2) { Appeal.create(vacols_id: "456D") }
    let!(:task2) { EstablishClaim.create(appeal: appeal2) }
    subject { Task.newest_first }
    before do
      task1.update(created_at: 10.days.ago)
      task2.update(created_at: 1.day.ago)
    end

    it "orders correctly" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(subject.first).to eq(task2)
      expect(subject.last).to eq(task1)
    end
  end

  context ".oldest_first" do
    let!(:appeal1) { Appeal.create(vacols_id: "123C") }
    let!(:task1) { EstablishClaim.create(appeal: appeal1) }
    let!(:appeal2) { Appeal.create(vacols_id: "456D") }
    let!(:task2) { EstablishClaim.create(appeal: appeal2) }
    subject { Task.oldest_first }
    before do
      task1.update(created_at: 10.days.ago)
      task2.update(created_at: 1.day.ago)
    end

    it "orders correctly" do
      expect(subject).to be_an_instance_of(Task::ActiveRecord_Relation)
      expect(subject.first).to eq(task1)
      expect(subject.last).to eq(task2)
    end
  end

  context ".progress_status" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    subject { task.progress_status }

    # We start with a blank task and move it task through the various states

    context "starts as unassigned" do
      it { is_expected.to eq("Unassigned") }
    end

    context "task is assigned" do
      before do
        task.prepare!
        task.assign!(:assigned, @user)
      end

      it { is_expected.to eq("Not Started") }
    end

    context "task is started" do
      let!(:appeal) { Appeal.create(vacols_id: "123C") }
      let!(:task) { EstablishClaim.create(appeal: appeal) }
      before do
        task.prepare!
        task.assign!(:assigned, @user)
        task.start!
      end
      it { is_expected.to eq("In Progress") }
    end

    context "task is completed" do
      before do
        task.prepare!
        task.assign!(:assigned, @user)
        task.start!
        task.review!
        task.complete!(:completed, status: 0)
      end

      it { is_expected.to eq("Completed") }
    end
  end

  context ".start!" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    it "errors if no one is assigned" do
      expect(task.user).to be_nil
      expect { task.start! }.to raise_error(AASM::InvalidTransition)
    end

    it "sets started_at value to current timestamp" do
      task.prepare!
      task.assign!(:assigned, @user)
      expect(task.started_at).to be_falsey
      task.start!
      expect(task.started_at).to eq(Time.now.utc)
    end
  end

  context ".started?" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    subject { task.started? }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
    end

    context "not started" do
      it { is_expected.to be_falsey }
    end

    context "was started" do
      before { task.start! }
      it { is_expected.to be_truthy }
    end
  end

  context ".special_issue_not_emailed?" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    let!(:completion_status) { :special_issue_not_emailed }
    subject { task }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
      task.start!
      task.complete!(status: completion_status)
    end
    it { expect(subject.special_issue_not_emailed?).to be_truthy }
  end

  context ".completed?" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    subject { task }
    before { task.completed_at = Time.now.utc }
    it { expect(subject.completed_at).to be_truthy }
  end

  context "#completed_today" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.update_attributes!(completed_at: Time.now.utc)
    end
    it { expect { Task.completed_today.find(task.id) }.not_to raise_error }
  end

  context "#complete_and_recreate!" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
      task.start!
      task.review!
      task.complete_and_recreate!(3)
    end
    it "completes and creates a new task" do
      new_task = appeal.tasks.where(type: task.type).where.not(aasm_state: "completed").first
      expect(task.completed?).to be_truthy
      expect(task.id).not_to eq(new_task.id)
    end

    it "fails on already completed tasks" do
      expect(task.reload.completed?).to be_truthy
      expect { task.cancel! }.to raise_error(AASM::InvalidTransition)
    end
  end

  context "#complete!" do
    subject { task.complete!(params) }
    let(:params) { { status: :routed_to_ro, outgoing_reference_id: "123WOO" } }

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

      it "completes the task without outgoing_reference_id" do
        subject

        expect(task.reload).to have_attributes(
          completed_at: Time.zone.now,
          completion_status: "routed_to_ro",
          outgoing_reference_id: nil
        )
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

  context "#to_complete" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.prepare!
    end
    it { expect { Task.to_complete.find(task.id) }.not_to raise_error }
  end

  context "#expire!" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
      task.start!
    end
    it "closes unfinished tasks" do
      task.expire!
      expect(task.reload.completed?).to be_truthy
      expect(task.reload.completion_status).to eq("expired")
      expect(appeal.tasks.where.not(aasm_state: "completed").where(type: :EstablishClaim).count).to eq(1)
    end

    it "closes unfinished task in review state" do
      task.review!
      task.expire!
      expect(task.reload.completed?).to be_truthy
      expect(task.reload.completion_status).to eq("expired")
      expect(appeal.tasks.where.not(aasm_state: "completed").where(type: :EstablishClaim).count).to eq(1)
    end
  end

  context "#completed_success" do
    let!(:successful_task) { Generators::EstablishClaim.create(completed_at: 30.minutes.ago, completion_status: 0) }
    let!(:canceled_task) { Generators::EstablishClaim.create(completed_at: 30.minutes.ago, completion_status: 1) }
    it "returns only the successfully completed task" do
      expect(Task.completed_success).to eq [successful_task]
    end
  end

  context "#cancel!" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
      task.start!
    end
    it "closes canceled tasks" do
      task.cancel!
      expect(task.reload.completed?).to be_truthy
      expect(task.reload.completion_status).to eq("canceled")
      expect(appeal.tasks.to_complete.where(type: :EstablishClaim).count).to eq(0)
    end

    it "saves feedback" do
      task.cancel!("Feedback")
      expect(task.reload.comment).to eq("Feedback")
    end
  end

  context ".canceled?" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
      task.start!
    end
    it "returns false for task not canceled" do
      expect(task.canceled?).to be_falsey
    end

    it "returns true for canceled task" do
      task.cancel!
      expect(task.canceled?).to be_truthy
    end

    it "can be canceled when in review state" do
      task.review!
      task.cancel!
      expect(task.canceled?).to be_truthy
    end
  end

  context "#assigned_not_completed" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    before do
      task.prepare!
      task.assign!(:assigned, @user)
    end
    it { expect { Task.assigned_not_completed.find(task.id) }.not_to raise_error }
  end

  context "#days_since_creation" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal, created_at: @one_week_ago) }
    it "returns the correct number of days" do
      expect(task.days_since_creation).to eq(7)
    end
  end

  context "#unprepared" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:task) { EstablishClaim.create(appeal: appeal) }
    it "returns unprepared tasks" do
      expect(Task.unprepared.first).to eq(task)
    end
  end

  context "#tasks_completed_by_users" do
    let!(:appeal) { Appeal.create(vacols_id: "123C") }
    let!(:tasks) do
      [
        EstablishClaim.create(appeal: appeal),
        EstablishClaim.create(appeal: appeal),
        EstablishClaim.create(appeal: appeal)
      ]
    end

    before do
      tasks.each_with_index do |task, index|
        task.prepare!
        if index < 2
          task.assign!(:assigned, @user)
        else
          task.assign!(:assigned, @user2)
        end
        task.start!
        task.review!
        task.complete!(status: 0)
      end
    end

    it "returns hash with each user and their completed number of tasks" do
      expect(Task.tasks_completed_by_users(tasks)).to eq("Jane Doe" => 1, "Robert Smith" => 2)
    end
  end

  context "#should_assign?" do
    subject { task.should_assign? }

    it { is_expected.to be_truthy }

    context "if task is invalid" do
      let(:appeal) { Generators::Appeal.create(vbms_id: "INVALID") }

      it "invalidates the task and returns false" do
        is_expected.to be_falsey
        expect(task.reload).to be_invalidated
      end
    end

    context "if task isn't accessible by the logged in user" do
      let(:appeal) { Generators::Appeal.create(inaccessible: true) }
      it { is_expected.to be_falsey }
    end
  end

  context ".any_assignable_to?" do
    subject { FakeTask.any_assignable_to?(user) }

    context "when user already has an assigned task" do
      let!(:assigned_task) do
        FakeTask.create!(aasm_state: :started, user: user, appeal: Generators::Appeal.create)
      end

      it { is_expected.to eq(true) }
    end

    context "when there are assignable tasks" do
      let!(:next_assignable_task) do
        FakeTask.create!(aasm_state: :unassigned, appeal: Generators::Appeal.create)
      end

      it { is_expected.to eq(true) }
    end

    context "when there are no assignable tasks" do
      let!(:completed_task) do
        FakeTask.create!(aasm_state: :completed, appeal: Generators::Appeal.create)
      end

      it { is_expected.to eq(false) }
    end

    context "when there is an invalid task" do
      let!(:invalid_task) do
        FakeTask.create!(
          appeal: Generators::Appeal.create(vbms_id: "INVALID"),
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
          created_at: 40.seconds.ago,
          user: user,
          appeal: Generators::Appeal.create
        )
      end

      let!(:next_assignable_task) do
        FakeTask.create!(
          aasm_state: :unassigned,
          created_at: 39.seconds.ago,
          appeal: Generators::Appeal.create
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
          appeal: Generators::Appeal.create(inaccessible: true)
        )
      end

      let!(:completed_task) do
        FakeTask.create!(
          aasm_state: :completed,
          created_at: 34.seconds.ago,
          appeal: Generators::Appeal.create
        )
      end

      let!(:unprepared_task) do
        FakeTask.create!(
          aasm_state: :unprepared,
          created_at: 33.seconds.ago,
          appeal: Generators::Appeal.create
        )
      end

      context "when there are assignable tasks" do
        let!(:after_next_assignable_task) do
          FakeTask.create!(
            aasm_state: :unassigned,
            created_at: 31.seconds.ago,
            appeal: Generators::Appeal.create
          )
        end

        let!(:next_assignable_task) do
          FakeTask.create!(
            aasm_state: :unassigned,
            created_at: 32.seconds.ago,
            appeal: Generators::Appeal.create
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
              appeal: Generators::Appeal.create(vbms_id: "INVALID"),
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
end
