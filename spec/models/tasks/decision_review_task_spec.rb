describe DecisionReviewTask do
  describe "#label" do
    subject { create(:higher_level_review_task).becomes(described_class) }

    it "uses the review_title of the parent appeal" do
      expect(subject.label).to eq "Higher-Level Review"
    end
  end
end
