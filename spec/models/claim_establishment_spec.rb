describe ClaimEstablishment do
  let(:appeal_remand) do
    Generators::Appeal.build(vacols_record: Fakes::AppealRepository.appeal_remand_decided)
  end

  let(:appeal_full_grant) do
    Generators::Appeal.build(vacols_record: Fakes::AppealRepository.appeal_full_grant_decided)
  end

  context ".get_decision_type" do
    it "returns the right decision type based on the appeal information passed in" do
      expect(ClaimEstablishment.get_decision_type(appeal_full_grant)).to eq(:full_grant)
      expect(ClaimEstablishment.get_decision_type(appeal_remand)).to eq(:remand)
    end
  end

  context "#appeal=" do
    let(:claim_establishment) { ClaimEstablishment.new }

    it "sets the decision_type" do
      claim_establishment.appeal = appeal_remand
      expect(claim_establishment).to be_remand

      claim_establishment.appeal = appeal_full_grant
      expect(claim_establishment).to be_full_grant
    end
  end
end
