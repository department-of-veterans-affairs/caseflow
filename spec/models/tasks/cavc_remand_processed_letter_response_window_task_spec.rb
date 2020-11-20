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

        expect(appeal.tasks).to include new_task
        expect(parent_task.children).to include new_task
        child_tasks = new_task.children.where(type: :TimedHoldTask)
        expect(child_tasks.count).to eq 1
        expect(child_tasks.first.assigned_to).to eq CavcLitigationSupport.singleton

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
    let(:org_admin) do
      create(:user) do |u|
        OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton)
      end
    end
    let(:org_nonadmin) { create(:user) { |u| CavcLitigationSupport.singleton.add_user(u) } }
    let(:other_user) { create(:user) }
    let(:send_task) { create(:send_cavc_remand_processed_letter_task) }
    # context "task assigned to CavcLitigationSupport admin" do
    #   it "returns admin actions" do
    #     expect(send_task.available_actions(org_admin)).to match_array SendCRPLetterTask::ADMIN_ACTIONS
    #     expect(send_task.available_actions(other_user)).to be_empty
    #   end
    # end
    context "task assigned to CavcLitigationSupport non-admin" do
      let(:user_task) { create(:send_cavc_remand_processed_letter_task, parent: send_task, assigned_to: org_nonadmin) }
      let(:window_task) do
        user_task.update_from_params({ status: "completed" }, org_nonadmin)
        user_task.appeal.tasks.where(type: CRPLRWindowTask.name).first
      end
      it "returns non-admin actions" do
        expect(user_task.available_actions(org_nonadmin)).to match_array SendCRPLetterTask::USER_ACTIONS
        expect(window_task.available_actions(org_nonadmin)).to match_array CRPLRWindowTask::USER_ACTIONS
      end
    end
  end
end
