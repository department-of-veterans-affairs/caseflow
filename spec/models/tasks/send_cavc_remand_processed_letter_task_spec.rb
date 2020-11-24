# frozen_string_literal: true

describe SendCavcRemandProcessedLetterTask, :postgres do
  require_relative "task_shared_examples.rb"
  SendCRPLetterTask = SendCavcRemandProcessedLetterTask

  let(:org_admin) { create(:user) { |u| OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton) } }
  let(:org_nonadmin) { create(:user) { |u| CavcLitigationSupport.singleton.add_user(u) } }
  let(:other_user) { create(:user) }

  describe ".create" do
    subject { described_class.create(appeal: appeal, parent: parent_task) }
    let(:appeal) { create(:appeal) }
    let!(:parent_task) { create(:cavc_task, appeal: appeal) }
    let(:parent_task_class) { CavcTask }

    it_behaves_like "task requiring specific parent"

    it "has expected defaults" do
      new_task = subject
      expect(new_task.assigned_to).to eq CavcLitigationSupport.singleton
      expect(new_task.label).to eq COPY::SEND_CAVC_REMAND_PROCESSED_LETTER_TASK_LABEL
      expect(new_task.default_instructions).to be_empty
    end

    context "creation of child task assigned to user" do
      let!(:parent_task) { create(:send_cavc_remand_processed_letter_task, appeal: appeal) }
      it "creates child task with defaults" do
        new_task = subject
        expect(new_task.valid?)
        expect(new_task.errors.messages[:parent]).to be_empty

        expect(appeal.tasks).to include new_task
        expect(parent_task.children).to include new_task

        expect(new_task.label).to eq COPY::SEND_CAVC_REMAND_PROCESSED_LETTER_TASK_LABEL
        expect(new_task.default_instructions).to be_empty
      end
    end
  end

  describe "FactoryBot.create(:send_cavc_remand_processed_letter_task) with different arguments" do
    context "appeal is provided" do
      let(:appeal) { create(:appeal) }
      let!(:cavc_task) { create(:cavc_task, appeal: appeal) }
      let!(:send_task) { create(:send_cavc_remand_processed_letter_task, appeal: appeal) }
      it "finds existing parent_task to use as parent" do
        expect(Appeal.count).to eq 1
        expect(RootTask.count).to eq 1
        expect(DistributionTask.count).to eq 1
        expect(CavcTask.count).to eq 1
        expect(SendCavcRemandProcessedLetterTask.count).to eq 1
        expect(send_task.parent).to eq cavc_task
      end
    end
    context "parent task is provided" do
      let!(:parent_task) { create(:cavc_task) }
      let!(:send_task) { create(:send_cavc_remand_processed_letter_task, parent: parent_task) }
      it "uses existing parent_task" do
        expect(Appeal.count).to eq 1
        expect(RootTask.count).to eq 1
        expect(DistributionTask.count).to eq 1
        expect(CavcTask.count).to eq 1
        expect(SendCavcRemandProcessedLetterTask.count).to eq 1
        expect(send_task.parent).to eq parent_task
      end
    end
    context "nothing is provided" do
      let!(:send_task) { create(:send_cavc_remand_processed_letter_task) }
      it "creates realistic task tree" do
        expect(Appeal.count).to eq 1
        expect(RootTask.count).to eq 1
        expect(DistributionTask.count).to eq 1
        expect(CavcTask.count).to eq 1
        expect(SendCavcRemandProcessedLetterTask.count).to eq 1
        expect(send_task.parent).to eq CavcTask.first
      end
    end
  end

  describe "#available_actions" do
    let(:send_task) { create(:send_cavc_remand_processed_letter_task) }
    let(:child_task) { create(:send_cavc_remand_processed_letter_task, parent: send_task, assigned_to: org_nonadmin) }

    context "task assigned to CavcLitigationSupport (aka org-task)" do
      it "returns admin actions" do
        expect(send_task.assigned_to).to eq CavcLitigationSupport.singleton
        expect(send_task.available_actions(org_admin)).to match_array SendCRPLetterTask::ADMIN_ACTIONS
        expect(send_task.available_actions(other_user)).to be_empty
      end
    end

    context "task assigned to CavcLitigationSupport non-admin (aka user-task)" do
      it "returns non-admin actions" do
        expect(child_task.assigned_to).to eq org_nonadmin
        expect(child_task.available_actions(org_nonadmin)).to match_array SendCRPLetterTask::USER_ACTIONS
        expect(child_task.available_actions(other_user)).to be_empty
      end
    end

    context "when SendCRPLetterTask completed" do
      let(:user_task) { child_task }
      subject { user_task.update_from_params({ status: Constants.TASK_STATUSES.completed }, org_nonadmin) }

      it "status is updated to be completed and 90-day window task is created" do
        expect { subject }.to_not raise_error
        expect(user_task.status).to eq Constants.TASK_STATUSES.completed

        window_task = user_task.appeal.tasks.where(type: CavcRemandProcessedLetterResponseWindowTask.name).first
        child_timed_hold_tasks = window_task.children.where(type: :TimedHoldTask)
        expect(child_timed_hold_tasks.first.timer_end_time.to_date).to eq(Time.zone.now.to_date + 90.days)
      end

      context "when user_task cannot be marked complete" do
        before { allow(user_task).to receive(:update_from_params).and_raise(StandardError) }
        it "does not create CavcRemandProcessedLetterResponseWindowTask" do
          expect(user_task.available_actions(org_nonadmin)).to match_array SendCRPLetterTask::USER_ACTIONS
          expect { subject }.to raise_error(StandardError)
          expect(user_task.status).to eq Constants.TASK_STATUSES.assigned
        end
      end
    end
  end
end
