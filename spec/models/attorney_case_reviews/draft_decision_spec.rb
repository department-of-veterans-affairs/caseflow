describe DraftDecision do

  context ".create" do

    subject { DraftDecision.create }

    it "should create AttorneyCaseReview of type DraftDecision" do
      expect(subject.type).to eq "DraftDecision"
    end
  end
end