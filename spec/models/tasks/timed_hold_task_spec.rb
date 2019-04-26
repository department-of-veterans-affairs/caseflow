# frozen_string_literal: true

describe TimedHoldTask do
  let(:task) { FactoryBot.create(:timed_hold_task) }

  describe ".create!" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:parent) { FactoryBot.create(:generic_task) }
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

      context "when there are closed sibling tasks" do
        let!(:cancelled_sibling) do
          FactoryBot.create(:timed_hold_task, **args.merge(status: Constants.TASK_STATUSES.cancelled))
        end
        let!(:completed_sibling) do
          FactoryBot.create(:timed_hold_task, **args.merge(status: Constants.TASK_STATUSES.completed))
        end

        it "does not change the status of the closed sibling tasks" do
          expect(subject.active?).to be_truthy
          expect(cancelled_sibling.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(completed_sibling.status).to eq(Constants.TASK_STATUSES.completed)
        end
      end

      context "when there is an active sibling task" do
        let!(:existing_timed_hold_task) { FactoryBot.create(:timed_hold_task, **args) }

        it "cancels the existing sibling tasks" do
          expect(subject.active?).to be_truthy
          expect(existing_timed_hold_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
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

      it "sets assigned_by to parent assigned_to" do
        expect(subject.assigned_by).to eq(parent.assigned_to)
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

      it "changes task status to completed" do
        subject
        expect(task.status).to eq(Constants.TASK_STATUSES.completed)
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
