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

  describe "#ui_hash" do
    let(:veteran) { create(:veteran) }
    let(:appeal) { create(:appeal, veteran_file_number: veteran.file_number) }
    let(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
    let(:task) do
      create(:veteran_record_request_task, appeal: appeal, assigned_to: non_comp_org)
    end

    it "renders JSON" do
      expect(task.ui_hash[:type]).to eq("Record Request")
    end
  end
end
