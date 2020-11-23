# frozen_string_literal: true

describe CavcRemandProcessedLetterResponseWindowTask, :postgres do
  require_relative "task_shared_examples.rb"

  describe ".create" do
    subject { described_class.create(parent: parent_task, appeal: appeal) }
    let(:appeal) { create(:appeal) }
    let!(:parent_task) { create(:cavc_task, appeal: appeal) }
    let(:parent_task_class) { CavcTask }

    it_behaves_like "task requiring specific parent"

    it "has expected defaults" do
      new_task = subject
      expect(new_task.assigned_to).to eq CavcLitigationSupport.singleton
      expect(new_task.label).to eq COPY::CAVC_REMAND_PROCESSED_LETTER_RESP_WINDOW_TASK_LABEL
      expect(new_task.default_instructions).to eq [COPY::CAVC_TASK_DEFAULT_INSTRUCTIONS]
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

        expect(new_task.label).to eq COPY::CAVC_REMAND_PROCESSED_LETTER_RESP_WINDOW_TASK_LABEL
        expect(new_task.default_instructions).to eq [COPY::CAVC_TASK_DEFAULT_INSTRUCTIONS]
      end
    end
  end

  # describe "FactoryBot.create(:send_cavc_remand_processed_letter_task) with different arguments" do
  #   context "appeal is provided" do
  #     let(:appeal) { create(:appeal) }
  #     let!(:cavc_task) { create(:cavc_task, appeal: appeal) }
  #     let!(:send_task) { create(:send_cavc_remand_processed_letter_task, appeal: appeal) }
  #     it "finds existing parent_task to use as parent" do
  #       expect(Appeal.count).to eq 1
  #       expect(RootTask.count).to eq 1
  #       expect(DistributionTask.count).to eq 1
  #       expect(CavcTask.count).to eq 1
  #       expect(SendCavcRemandProcessedLetterTask.count).to eq 1
  #       expect(send_task.parent).to eq cavc_task
  #     end
  #   end
  #   context "parent task is provided" do
  #     let!(:parent_task) { create(:cavc_task) }
  #     let!(:send_task) { create(:send_cavc_remand_processed_letter_task, parent: parent_task) }
  #     it "uses existing parent_task" do
  #       expect(Appeal.count).to eq 1
  #       expect(RootTask.count).to eq 1
  #       expect(DistributionTask.count).to eq 1
  #       expect(CavcTask.count).to eq 1
  #       expect(SendCavcRemandProcessedLetterTask.count).to eq 1
  #       expect(send_task.parent).to eq parent_task
  #     end
  #   end
  #   context "nothing is provided" do
  #     let!(:send_task) { create(:send_cavc_remand_processed_letter_task) }
  #     it "creates realistic task tree" do
  #       expect(Appeal.count).to eq 1
  #       expect(RootTask.count).to eq 1
  #       expect(DistributionTask.count).to eq 1
  #       expect(CavcTask.count).to eq 1
  #       expect(SendCavcRemandProcessedLetterTask.count).to eq 1
  #       expect(send_task.parent).to eq CavcTask.first
  #     end
  #   end
  # end

  SendCRPLetterTask = SendCavcRemandProcessedLetterTask
  CRPLRWindowTask = CavcRemandProcessedLetterResponseWindowTask
  describe "#available_actions" do
    Timecop.travel(17.days.ago)
    let(:org_admin) do
      create(:user) do |u|
        OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton)
      end
    end
    let(:org_nonadmin) { create(:user) { |u| CavcLitigationSupport.singleton.add_user(u) } }
    let(:other_user) { create(:user) }
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

        Timecop.travel(Time.zone.now + 90.days + 1.hour)
        TaskTimerJob.perform_now
        child_timed_hold_tasks = window_task.children.where(type: :TimedHoldTask)
        expect(child_timed_hold_tasks.first.status).to eq Constants.TASK_STATUSES.completed
        expect(window_task.reload.status).to eq Constants.TASK_STATUSES.assigned
      end

      context "when user_task cannot be marked complete" do
        before { allow(user_task).to receive(:update_from_params).and_raise(StandardError) }
        it "does not create window_task" do
          expect(user_task.available_actions(org_nonadmin)).to match_array SendCRPLetterTask::USER_ACTIONS
          expect { window_task }.to raise_error(StandardError)
          expect(user_task.appeal.tasks.where(type: CRPLRWindowTask.name).count).to eq 0
          expect(user_task.status).to eq Constants.TASK_STATUSES.assigned
        end
      end
    end
  end
end
