# frozen_string_literal: true

describe EducationDocumentSearchTask, :postgres do
  let(:task) { create(:education_document_search_task) }
  let(:emo) { EducationEmo.singleton }
  let(:user) { create(:user) }

  before { emo.add_user(user) }

  describe ".label" do
    it "uses a friendly label" do
      expect(task.class.label).to eq COPY::REVIEW_DOCUMENTATION_TASK_LABEL
    end
  end

  describe "#available_actions" do
    subject { task.available_actions(user) }

    it { is_expected.to eq EducationDocumentSearchTask::TASK_ACTIONS }
  end
end
