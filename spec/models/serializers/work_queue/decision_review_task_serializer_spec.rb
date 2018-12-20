describe WorkQueue::DecisionReviewTaskSerializer do
  let(:veteran) { create(:veteran) }
  let(:hlr) { create(:higher_level_review, veteran_file_number: veteran.file_number) }
  let(:task) { create(:higher_level_review_task, appeal: hlr).becomes(DecisionReviewTask) }

  subject { described_class.new(task) }

  describe "#as_json" do
    it "renders ready for client consumption" do
      expect(subject.as_json).to eq(claimant: nil,
                                    appeal: { id: hlr.id.to_s, isLegacyAppeal: false, issueCount: 0 },
                                    url: "TODO",
                                    veteran_ssn: veteran.ssn,
                                    assigned_on: task.assigned_at,
                                    type: "Higher-Level Review")
    end
  end
end
