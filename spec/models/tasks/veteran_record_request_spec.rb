# frozen_string_literal: true

describe VeteranRecordRequest, :postgres do
  let(:task) { create(:veteran_record_request_task) }

  describe "#label" do
    it "uses a friendly label" do
      expect(task.label).to eq "Record Request"
    end
  end

  describe "#serializer_class" do
    subject { task.serializer_class }

    it { is_expected.to eq(WorkQueue::VeteranRecordRequestSerializer) }
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
