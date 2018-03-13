describe OMORequest do
  context ".create" do
    subject { OMORequest.create }

    it "should create AttorneyCaseReview of type OMORequest" do
      expect(subject.type).to eq "OMORequest"
    end
  end
end
