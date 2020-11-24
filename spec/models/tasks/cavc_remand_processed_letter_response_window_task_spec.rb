# frozen_string_literal: true

describe CavcRemandProcessedLetterResponseWindowTask, :postgres do
  require_relative "task_shared_examples.rb"
  let(:org_admin) { create(:user) { |u| OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton) } }
  let(:org_nonadmin) { create(:user) { |u| CavcLitigationSupport.singleton.add_user(u) } }
  let(:other_user) { create(:user) }

  describe ".create" do
    subject { described_class.create(parent: parent_task, appeal: appeal) }
    let(:appeal) { create(:appeal) }
    let!(:parent_task) { create(:cavc_task, appeal: appeal) }
    let(:parent_task_class) { CavcTask }

    it_behaves_like "task requiring specific parent"

    it "has expected defaults" do
      new_task = subject
      expect(new_task.assigned_to).to eq CavcLitigationSupport.singleton
      expect(new_task.label).to eq COPY::CRP_LETTER_RESP_WINDOW_TASK_LABEL
      expect(new_task.default_instructions).to eq [COPY::CRP_LETTER_RESP_WINDOW_TASK_DEFAULT_INSTRUCTIONS]
    end

    describe ".create_with_hold" do
      subject { described_class.create_with_hold(parent_task) }

      it "creates task with child TimedHoldTask" do
        new_task = subject
        expect(new_task.valid?)
        expect(new_task.assigned_to).to eq CavcLitigationSupport.singleton
        expect(new_task.status).to eq Constants.TASK_STATUSES.on_hold

        expect(appeal.tasks).to include new_task
        expect(parent_task.children).to include new_task
        child_timed_hold_tasks = new_task.children.where(type: :TimedHoldTask)
        expect(child_timed_hold_tasks.count).to eq 1
        expect(child_timed_hold_tasks.first.assigned_to).to eq CavcLitigationSupport.singleton
        expect(child_timed_hold_tasks.first.status).to eq Constants.TASK_STATUSES.assigned
        expect(child_timed_hold_tasks.first.timer_end_time.to_date).to eq(Time.zone.now.to_date + 90.days)

        expect(new_task.label).to eq COPY::CRP_LETTER_RESP_WINDOW_TASK_LABEL
        expect(new_task.default_instructions).to eq [COPY::CRP_LETTER_RESP_WINDOW_TASK_DEFAULT_INSTRUCTIONS]
      end
    end
  end

  SendCRPLetterTask = SendCavcRemandProcessedLetterTask
  CRPLRWindowTask = CavcRemandProcessedLetterResponseWindowTask
  describe "#available_actions" do
    let(:send_task) { create(:send_cavc_remand_processed_letter_task) }

    context "window task created after SendCRPLetterTask completed" do
      let(:user_task) { create(:send_cavc_remand_processed_letter_task, parent: send_task, assigned_to: org_nonadmin) }
      let(:window_task) do
        user_task.update_from_params({ status: Constants.TASK_STATUSES.completed }, org_nonadmin)
        user_task.appeal.tasks.where(type: CRPLRWindowTask.name).first
      end
      it "returns available actions" do
        expect(user_task.available_actions(org_nonadmin)).to match_array SendCRPLetterTask::USER_ACTIONS
        expect(window_task.available_actions(org_nonadmin)).to include Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
        expect(window_task.reload.status).to eq Constants.TASK_STATUSES.on_hold
        expect(window_task.available_actions(other_user)).to be_empty

        Timecop.travel(Time.zone.now + 90.days + 1.hour)
        TaskTimerJob.perform_now
        child_timed_hold_tasks = window_task.children.where(type: :TimedHoldTask)
        expect(child_timed_hold_tasks.first.status).to eq Constants.TASK_STATUSES.completed
        expect(window_task.reload.status).to eq Constants.TASK_STATUSES.assigned
      end
    end
  end
end
