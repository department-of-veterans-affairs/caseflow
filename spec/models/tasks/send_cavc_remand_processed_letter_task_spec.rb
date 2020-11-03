# frozen_string_literal: true

describe SendCavcRemandProcessedLetterTask, :postgres do
  require_relative "task_shared_examples.rb"

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

    # TODO: create child_send_task/user_task
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
      end
    end
  end

  describe "#available_actions" do
    let(:org_admin) do
      create(:user) do |u|
        CavcLitigationSupport.singleton.add_user(u)
        OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton)
      end
    end
    let(:org_nonadmin) { create(:user) { |u| CavcLitigationSupport.singleton.add_user(u) } }
    let(:other_user) { create(:user) }
    let(:send_task) { create(:send_cavc_remand_processed_letter_task) }
    context "task assigned to CavcLitigationSupport admin" do
      it "returns admin actions" do
        expect(send_task.available_actions(org_admin)).to match_array SendCavcRemandProcessedLetterTask::ADMIN_ACTIONS
      end
    end
    context "task assigned to CavcLitigationSupport non-admin" do
      let(:child_send_task) { create(:send_cavc_remand_processed_letter_task, parent: send_task, assigned_to: org_nonadmin) }
      it "returns non-admin actions" do
        expect(child_send_task.available_actions(org_nonadmin)).to match_array SendCavcRemandProcessedLetterTask::USER_ACTIONS

        # expect(send_task.available_actions(other_user)).to be_empty
      end
    end
  end
end
