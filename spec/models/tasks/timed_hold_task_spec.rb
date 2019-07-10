# frozen_string_literal: true

require "rails_helper"

describe TimedHoldTask do
  let(:task) { FactoryBot.create(:timed_hold_task) }

  describe ".create!" do
    let(:parent) { FactoryBot.create(:generic_task) }
    let(:appeal) { parent.appeal }
    let(:initial_args) do
      { appeal: appeal,
        assigned_to: FactoryBot.create(:user),
        days_on_hold: 18,
        parent: parent }
    end

    subject { TimedHoldTask.create!(**args) }

    context "without a parent task" do
      let(:args) { initial_args.reject { |key, _| key == :parent } }

      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::InvalidParentTask)
      end
    end

    context "with parent_id argument instead of parent" do
      let(:args) do
        initial_args.reject { |key, _| key == :parent }.merge(parent_id: FactoryBot.create(:generic_task).id)
      end

      it "creates task successfully" do
        expect(subject).to be_an_instance_of(TimedHoldTask)
      end
    end

    context "without days_on_hold argument" do
      let(:args) { initial_args.reject { |key, _| key == :days_on_hold } }

      it "raises an error" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "with all required arguments" do
      let(:args) { initial_args }

      it "creates task successfully" do
        expect(subject).to be_an_instance_of(TimedHoldTask)
      end
    end

    describe "after_create(:cancel_active_siblings)" do
      let(:args) { initial_args }

      context "when there are no sibling tasks" do
        it "creates task successfully" do
          expect(subject).to be_an_instance_of(TimedHoldTask)
        end
      end

      context "when there are closed sibling TimedHoldTasks" do
        let!(:cancelled_sibling) do
          FactoryBot.create(:timed_hold_task, **args.merge(status: Constants.TASK_STATUSES.cancelled))
        end
        let!(:completed_sibling) do
          FactoryBot.create(:timed_hold_task, **args.merge(status: Constants.TASK_STATUSES.completed))
        end

        it "does not change the status of the closed sibling tasks" do
          expect(subject.open?).to be_truthy
          expect(cancelled_sibling.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(completed_sibling.status).to eq(Constants.TASK_STATUSES.completed)
        end
      end

      context "when there is an active sibling TimedHoldTask" do
        let!(:existing_timed_hold_task) { FactoryBot.create(:timed_hold_task, **args) }

        it "cancels the existing sibling task" do
          expect(subject.open?).to be_truthy
          expect(existing_timed_hold_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
        end
      end

      context "when there is an active sibling TimedHoldTask and an active sibling GenericTask" do
        let!(:existing_generic_task_sibling) { FactoryBot.create(:generic_task, parent: parent, appeal: appeal) }
        let!(:existing_timed_hold_task) { FactoryBot.create(:timed_hold_task, **args) }

        it "cancels the TimedHoldTask but leaves the GenericTask alone" do
          expect(subject.open?).to be_truthy
          expect(parent.children.count).to eq(3)
          expect(existing_timed_hold_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(existing_generic_task_sibling.reload.open?).to eq(true)
        end
      end
    end
  end

  describe ".create_from_parent" do
    let(:parent) { FactoryBot.create(:generic_task) }

    let(:days_on_hold) { 4 }
    let(:assigned_by) { FactoryBot.create(:user) }
    let(:instructions) { "" }

    let(:initial_args) do
      { days_on_hold: days_on_hold,
        assigned_by: assigned_by,
        instructions: instructions }
    end

    subject { TimedHoldTask.create_from_parent(parent, **args) }

    context "when there is no days_on_hold argument" do
      let(:args) { initial_args.reject { |key, _| key == :days_on_hold } }

      it "raises an error" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context "when there is no assigner argument" do
      let(:args) { initial_args.reject { |key, _| key == :assigned_by } }

      it "sets assigned_by to nil" do
        expect(subject.assigned_by).to eq(nil)
      end
    end

    context "when all arguments are set" do
      let(:args) { initial_args }

      it "sets appeal and places parent task on hold" do
        expect(subject.appeal).to eq(parent.appeal)
        expect(parent.status).to eq(Constants.TASK_STATUSES.on_hold)
      end
    end
  end

  describe ".when_timer_ends" do
    let(:task) { FactoryBot.create(:timed_hold_task, status: status) }

    subject { task.when_timer_ends }

    context "when the task is active" do
      let(:status) { Constants.TASK_STATUSES.in_progress }

      context "when the TimedHoldTask does not have a parent task" do
        it "changes task status to completed" do
          subject
          expect(task.status).to eq(Constants.TASK_STATUSES.completed)
        end
      end

      context "when the TimedHoldTask has a parent task assigned to an organization" do
        let(:parent_task) { FactoryBot.create(:generic_task, status: Constants.TASK_STATUSES.on_hold) }
        let(:task) { FactoryBot.create(:timed_hold_task, status: status, parent: parent_task) }
        it "sets the parent task status to assigned" do
          subject
          expect(parent_task.status).to eq(Constants.TASK_STATUSES.assigned)
        end
      end
    end

    context "when the task has already been completed" do
      let(:status) { Constants.TASK_STATUSES.completed }

      it "does not update the status of the task" do
        expect(task).to_not receive(:update!)
        subject
      end
    end

    context "when the task has been cancelled" do
      let(:status) { Constants.TASK_STATUSES.cancelled }

      it "does not change the status of the task" do
        expect(task).to_not receive(:update!)
        subject
        expect(task.status).to eq(Constants.TASK_STATUSES.cancelled)
      end
    end
  end

  context "start and end times" do
    let(:days_on_hold) { 18 }
    let(:user) { FactoryBot.create(:user) }
    let!(:parent) { FactoryBot.create(:generic_task, assigned_to: user) }
    let!(:task) do
      TimedHoldTask.create!(appeal: parent.appeal, assigned_to: user, days_on_hold: days_on_hold, parent: parent)
    end

    it "has one task timer" do
      expect(task.task_timers.count).to eq 1
    end

    describe ".timer_end_time" do
      it "returns the expected end time" do
        expect(task.reload.timer_end_time).to eq(
          task.task_timers.first.submitted_at + TaskTimer.processing_retry_interval_hours.hours
        )
      end
    end

    describe ".timer_start_time" do
      it "returns the expected start time" do
        expect(task.reload.timer_start_time).to eq task.task_timers.first.created_at
      end
    end
  end

  describe ".hide_from_case_timeline" do
    it "is always hidden from case timeline" do
      expect(task.hide_from_case_timeline).to eq(true)
    end
  end

  describe ".hide_from_task_snapshot" do
    it "is always hidden from task snapshot" do
      expect(task.hide_from_task_snapshot).to eq(true)
    end
  end
end
