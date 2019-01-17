describe WorkQueue::DecisionReviewTaskSerializer do
  let(:veteran) { create(:veteran) }
  let(:hlr) { create(:higher_level_review, veteran_file_number: veteran.file_number) }
  let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:task) { create(:higher_level_review_task, appeal: hlr, assigned_to: non_comp_org).becomes(DecisionReviewTask) }

  subject { described_class.new(task) }

  describe "#as_json" do
    it "renders ready for client consumption" do
      expect(subject.as_json).to eq(claimant: { name: hlr.veteran_full_name, relationship: "self" },
                                    appeal: { id: hlr.id.to_s, isLegacyAppeal: false, issueCount: 0 },
                                    veteran_participant_id: veteran.participant_id,
                                    assigned_on: task.assigned_at,
                                    completed_at: task.completed_at,
                                    started_at: task.started_at,
                                    tasks_url: "/decision_reviews/nco",
                                    id: task.id,
                                    created_at: task.created_at,
                                    type: "Higher-Level Review")
    end
  end
end
