# frozen_string_literal: true

describe VhaDocumentSearchTask, :postgres do
  let(:task) { create(:vha_document_search_task) }
  let(:camo) { VhaCamo.singleton }
  let(:user) { create(:user) }

  before { camo.add_user(user) }

  describe ".label" do
    before { FeatureToggle.enable!(:vha_predocket_workflow) }
    after { FeatureToggle.disable!(:vha_predocket_workflow) }
    it "uses a friendly label" do
      expect(task.class.label).to eq COPY::REVIEW_DOCUMENTATION_TASK_LABEL
    end
  end

  describe "#available_actions" do
    before { FeatureToggle.enable!(:vha_predocket_workflow) }
    after { FeatureToggle.disable!(:vha_predocket_workflow) }
    subject { task.available_actions(user) }

    it { is_expected.to eq VhaDocumentSearchTask::TASK_ACTIONS }
  end
end
