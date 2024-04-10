# frozen_string_literal: true

describe MdrTask, :postgres do
  require_relative "task_shared_examples.rb"
  let(:org_admin) { create(:user) { |u| OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton) } }
  let(:org_nonadmin) { create(:user) { |u| CavcLitigationSupport.singleton.add_user(u) } }
  let(:other_user) { create(:user) }

  let(:decision_date) { 5.days.ago.to_date }
  let(:cavc_remand) { create(:cavc_remand, decision_date: decision_date) }
  let(:appeal) { cavc_remand.remand_appeal }
  let(:cavc_task) { appeal.tasks.open.of_type(:CavcTask).last }

  describe ".create" do
    subject { described_class.create(parent: parent_task, appeal: appeal) }
    let(:parent_task) { cavc_task }
    let(:parent_task_class) { CavcTask }

    it_behaves_like "task requiring specific parent"

    it "has expected default values" do
      new_task = subject
      expect(new_task.assigned_to).to eq CavcLitigationSupport.singleton
      expect(new_task.label).to eq COPY::MDR_TASK_LABEL
      expect(new_task.default_instructions).to eq [COPY::MDR_WINDOW_TASK_DEFAULT_INSTRUCTIONS]
    end

    describe ".create_with_hold" do
      subject { described_class.create_with_hold(parent_task) }

      it "creates task with child TimedHoldTask" do
        new_task = subject
        expect(new_task).to be_valid
        expect(new_task.assigned_to).to eq CavcLitigationSupport.singleton
        expect(new_task.status).to eq Constants.TASK_STATUSES.on_hold

        expect(appeal.tasks).to include new_task
        expect(parent_task.children).to include new_task
        child_timed_hold_tasks = new_task.children.of_type(:TimedHoldTask)
        expect(child_timed_hold_tasks.count).to eq 1
        expect(child_timed_hold_tasks.first.assigned_to).to eq CavcLitigationSupport.singleton
        expect(child_timed_hold_tasks.first.status).to eq Constants.TASK_STATUSES.assigned
        expect(child_timed_hold_tasks.first.timer_end_time.to_date).to eq(decision_date + 90.days)

        expect(new_task.label).to eq COPY::MDR_TASK_LABEL
        expect(new_task.default_instructions).to eq [COPY::MDR_WINDOW_TASK_DEFAULT_INSTRUCTIONS]
      end
    end
  end

  describe "#available_actions" do
    let!(:mdr_task) { described_class.create_with_hold(cavc_task) }

    context "immediately after MdrTask is created" do
      it "returns available actions when MdrTask is on hold" do
        expect(mdr_task.reload.status).to eq Constants.TASK_STATUSES.on_hold
        child_timed_hold_tasks = mdr_task.children.of_type(:TimedHoldTask)
        expect(child_timed_hold_tasks.first.status).to eq Constants.TASK_STATUSES.assigned

        expect(mdr_task.available_actions(org_admin)).to include Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
        expect(mdr_task.available_actions(org_nonadmin)).to include Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
        expect(mdr_task.available_actions(other_user)).to be_empty
      end
    end

    context "after more than 90 days have passed since decision_date" do
      before do
        Timecop.travel(decision_date + 91.days)
        TaskTimerJob.perform_now
      end
      after do
        Timecop.return
      end

      it "marks MdrTask as assigned" do
        expect(mdr_task.reload.status).to eq Constants.TASK_STATUSES.assigned
        child_timed_hold_tasks = mdr_task.children.of_type(:TimedHoldTask)
        expect(child_timed_hold_tasks.first.status).to eq Constants.TASK_STATUSES.completed
      end

      it "shows correct actions" do
        actions = [
          Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
          Constants.TASK_ACTIONS.CAVC_REMAND_RECEIVED_MDR.to_h
        ]

        expect(mdr_task.available_actions(org_admin)).to match_array(actions)
        expect(mdr_task.available_actions(org_nonadmin)).to match_array(actions)
        expect(mdr_task.available_actions(other_user)).to be_empty
      end
    end
  end

  describe "#update_timed_hold" do
    let(:parent_task) { appeal.tasks.open.of_type(:CavcTask).last }
    let!(:mdr_task) { MdrTask.create_with_hold(parent_task) }

    subject { mdr_task.update_timed_hold }

    context "when the task calls update_timed_hold" do
      it "it will create a new timed hold task" do
        original_count = mdr_task.children.of_type(:TimedHoldTask).length

        expect { subject }.not_to raise_error

        expect(mdr_task.children.of_type(:TimedHoldTask).length).to eq original_count + 1
      end

      it "it will cancel the existing timed hold task" do
        expect(TimedHoldTask.first.status).not_to eq Constants.TASK_STATUSES.cancelled

        expect { subject }.not_to raise_error

        expect(TimedHoldTask.first.status).to eq Constants.TASK_STATUSES.cancelled
      end
    end
  end
end
