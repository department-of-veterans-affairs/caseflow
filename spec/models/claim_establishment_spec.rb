describe CreateEstablishClaimTasksJob do
  before do
    @remand = Fakes::AppealRepository.new("123C", :appeal_remand_decided)
    @full_grant = Fakes::AppealRepository.new("456D", :appeal_full_grant_decided, decision_date: 1.day.ago)
  end

  context "create_new_claim_establishment" do
    it "creates a claim with correct decision_type" do
      task = EstablishClaim.find_or_create_by(appeal: @remand)

      claim_establishment = ClaimEstablishment.create(
        decision_date: Time.zone.now,
        appeal: @remand,
        task: task
      )
      expect(claim_establishment.remand?).to eq(true)
    end
  end

  context ".get_decision_type" do
    it "returns the right decision type based on the appeal information passed in" do
      expect(ClaimEstablishment.get_decision_type(@full_grant)).to eq(:full_grant)
      expect(ClaimEstablishment.get_decision_type(@remand)).to eq(:remand)
    end
  end
end