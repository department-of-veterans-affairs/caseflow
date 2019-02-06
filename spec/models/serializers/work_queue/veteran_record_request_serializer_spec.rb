describe WorkQueue::VeteranRecordRequestSerializer do
  let(:veteran) { create(:veteran) }
  let(:appeal) { create(:appeal, veteran_file_number: veteran.file_number) }
  let(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:task) do
    create(:veteran_record_request_task, appeal: appeal, assigned_to: non_comp_org).becomes(VeteranRecordRequest)
  end

  subject { described_class.new(task) }

  describe "#as_json" do
    it "renders ready for client consumption" do
      expect(subject.as_json).to eq(claimant: { name: appeal.veteran_full_name, relationship: "self" },
                                    appeal: { id: appeal.uuid.to_s, isLegacyAppeal: false, issueCount: 0 },
                                    veteran_participant_id: veteran.participant_id,
                                    assigned_on: task.assigned_at,
                                    closed_at: task.closed_at,
                                    started_at: task.started_at,
                                    tasks_url: "/decision_reviews/nco",
                                    id: task.id,
                                    created_at: task.created_at,
                                    type: "Record Request")
    end
  end
end
