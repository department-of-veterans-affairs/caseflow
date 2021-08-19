# frozen_string_literal: true

describe VhaDocumentSearchTask, :postgres do
  let(:task) { create(:vha_document_search_task) }
  let(:camo) { VhaCamo.singleton }
  let(:user) { create(:user) }

  before { camo.add_user(user) }

  describe "#label" do
    it "uses a friendly label" do
      expect(task.label).to eq "Assess Documentation"
    end
  end

  describe "#available_actions" do
    subject { task.available_actions(user) }

    it { is_expected.to eq [] }
  end
end
