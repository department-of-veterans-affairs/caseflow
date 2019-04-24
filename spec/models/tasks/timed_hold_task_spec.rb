# frozen_string_literal: true

describe TimedHoldTask do
  let(:task) { FactoryBot.create(:timed_hold_task) }

  describe ".create!" do
    let(:initial_args) do
      {
        appeal: FactoryBot.create(:appeal),
        assigned_to: FactoryBot.create(:user),
        days_on_hold: 18,
        parent: FactoryBot.create(:generic_task)
      }
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
