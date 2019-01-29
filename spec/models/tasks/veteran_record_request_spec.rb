describe VeteranRecordRequest do
  describe "#label" do
    subject { create(:veteran_record_request_task).becomes(described_class) }

    it "uses a friendly label" do
      expect(subject.label).to eq "Record Request"
    end
  end
end
