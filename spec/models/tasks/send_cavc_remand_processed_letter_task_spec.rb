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

    context "task assigned to CavcLitigationSupport organization (aka org-task)" do
      it "returns org actions for an administrator" do
        expect(send_task.assigned_to).to eq CavcLitigationSupport.singleton
        expect(send_task.available_actions(org_admin)).to match_array SendCRPLetterTask::ORG_ACTIONS
        expect(send_task.available_actions(other_user)).to be_empty
      end

      it "returns org actions for a colleague" do
        expect(send_task.assigned_to).to eq CavcLitigationSupport.singleton
        expect(send_task.available_actions(org_nonadmin)).to match_array SendCRPLetterTask::ORG_ACTIONS
      end
    end

    context "task assigned to user on CavcLitigationSupport (aka user-task)" do
      let(:child_task) { create(:send_cavc_remand_processed_letter_task, parent: send_task, assigned_to: org_nonadmin) }

      it "returns user actions for all CAVC Lit Support team members" do
        expect(child_task.assigned_to).to eq org_nonadmin
        expect(child_task.available_actions(org_nonadmin)).to match_array SendCRPLetterTask::USER_ACTIONS
        expect(child_task.available_actions(org_admin)).to match_array SendCRPLetterTask::USER_ACTIONS
        expect(child_task.available_actions(other_user)).to be_empty
      end
    end

    context "when SendCRPLetterTask completed" do
      let(:user_task) { child_task }
      subject { user_task.update_from_params({ status: Constants.TASK_STATUSES.completed }, org_nonadmin) }

      it "status is updated to be completed and 90-day window task is created" do
        expect { subject }.to_not raise_error
        expect(user_task.status).to eq Constants.TASK_STATUSES.completed

        window_task = user_task.appeal.tasks.of_type(:CavcRemandProcessedLetterResponseWindowTask).first
        child_timed_hold_tasks = window_task.children.of_type(:TimedHoldTask)
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

  describe "#available_actions_unwrapper" do
    let(:cavc_user) { create(:user) }
    let(:cavc_task) { create(:send_cavc_remand_processed_letter_task, assigned_to: cavc_user) }

    subject { cavc_task.available_actions_unwrapper(cavc_task.assigned_to) }

    before do
      # Create completed distribution task to make sure we're picking the correct (open) parent
      completed_distribution_task = build(:task, appeal: cavc_task.appeal, type: DistributionTask.name)
      completed_distribution_task.save!(validate: false)
      completed_distribution_task.completed!
      CavcLitigationSupport.singleton.add_user(cavc_user)
    end

    it "provides the correct parent id for blocking and non blocking admin actions" do
      admin_actions = [
        [:SEND_TO_TRANSLATION_BLOCKING_DISTRIBUTION, TranslationTask, Translation],
        [:SEND_TO_TRANSCRIPTION_BLOCKING_DISTRIBUTION, TranscriptionTask, TranscriptionTeam],
        [:SEND_TO_PRIVACY_TEAM_BLOCKING_DISTRIBUTION, PrivacyActTask, PrivacyTeam],
        [:SEND_IHP_TO_COLOCATED_BLOCKING_DISTRIBUTION, IhpColocatedTask, Colocated],
        [:CLARIFY_POA_BLOCKING_CAVC, CavcPoaClarificationTask, CavcLitigationSupport, true]
      ]

      admin_actions.each do |admin_action, new_task_type, assignee, blocks_cavc_task|
        task_action = subject.detect { |action| action[:label] == Constants::TASK_ACTIONS[admin_action.to_s]["label"] }

        expect(task_action[:data][:type]).to eq new_task_type.name
        expect(task_action[:data][:selected]).to eq assignee.singleton

        parent = Task.find(task_action[:data][:parent_id])
        expected_parent = blocks_cavc_task ? cavc_task : cavc_task.parent.parent
        expected_parent_type = blocks_cavc_task ? SendCavcRemandProcessedLetterTask : DistributionTask
        expect(parent.type).to eq expected_parent_type.name
        expect(parent).to eq expected_parent
        expect(parent.appeal).to eq cavc_task.appeal
        expect(parent.open?).to be true
      end
    end

    context "when there is no open distribution task on the appeal" do
      before { DistributionTask.open.where(appeal: cavc_task.appeal).each(&:completed!) }

      it "provides no parent id to the front end" do
        translation_action = subject.detect do |action|
          action[:label] == Constants.TASK_ACTIONS.SEND_TO_TRANSLATION_BLOCKING_DISTRIBUTION.label
        end

        expect(translation_action[:data][:parent_id]).to be nil
      end
    end
  end

  describe "child task closes" do
    let(:send_task) { create(:send_cavc_remand_processed_letter_task) }
    let!(:child_task) { create(:cavc_poa_clarification_task, parent: send_task, assigned_by: org_admin) }

    let(:new_child_status) { :completed }
    subject { child_task.update(status: new_child_status) }
    let(:expected_parent_status) { :assigned }

    shared_examples "update parent task's status" do
      it "set correct parent task status" do
        expect(send_task.status).to eq("on_hold")
        expect(child_task.status).to eq("assigned")

        subject
        expect(child_task.status).to eq(new_child_status.to_s)
        expect(send_task.status).to eq(expected_parent_status.to_s)
      end
    end

    context "when completing non-SendCavcRemandProcessedLetterTask child task" do
      include_examples "update parent task's status"
    end
    context "when cancelling non-SendCavcRemandProcessedLetterTask child task" do
      let(:new_child_status) { :cancelled }
      include_examples "update parent task's status"
    end

    context "when closing SendCavcRemandProcessedLetterTask child task" do
      let(:child_task) { create(:send_cavc_remand_processed_letter_task, parent: send_task, assigned_by: org_admin) }

      context "when completing SendCavcRemandProcessedLetterTask child task" do
        let(:expected_parent_status) { :completed }
        include_examples "update parent task's status"
      end
      context "when cancelling child task" do
        let(:new_child_status) { :cancelled }
        let(:expected_parent_status) { :cancelled }
        include_examples "update parent task's status"
      end
    end
  end
end
