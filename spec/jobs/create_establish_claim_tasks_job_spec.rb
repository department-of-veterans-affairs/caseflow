require "rails_helper"

describe CreateEstablishClaimTasksJob do
  before do
    Timecop.freeze(Time.zone.local(2015, 2, 1, 12, 8, 0))

    FeatureToggle.enable!(:dispatch_full_grants)
    FeatureToggle.enable!(:dispatch_partial_grants_remands)
    @remand = Fakes::AppealRepository.new("123C", :appeal_remand_decided)
    @full_grant = Fakes::AppealRepository.new("456D", :appeal_full_grant_decided, decision_date: 1.day.ago)

    allow(AppealRepository).to receive(:remands_ready_for_claims_establishment).and_return([@remand])
    allow(AppealRepository).to receive(:amc_full_grants).and_return([@full_grant])
  end

  context ".perform" do
    it "finds or creates tasks" do
      expect(EstablishClaim.count).to eq(0)
      CreateEstablishClaimTasksJob.perform_now
      expect(EstablishClaim.count).to eq(2)
      # making sure that the establish claim metadata is poulated as well
      expect(ClaimEstablishment.count).to eq(2)

      # on re-run, the same 2 appeals should be found
      # so no new tasks are created
      CreateEstablishClaimTasksJob.perform_now
      expect(EstablishClaim.count).to eq(2)
      expect(ClaimEstablishment.count).to eq(2)
    end

    it "skips partial grants if they are disabled" do
      FeatureToggle.disable!(:dispatch_partial_grants_remands)
      expect(EstablishClaim.count).to eq(0)
      CreateEstablishClaimTasksJob.perform_now
      expect(EstablishClaim.count).to eq(1)
    end
  end

  context ".full_grant_outcoded_after" do
    subject { CreateEstablishClaimTasksJob.new.full_grant_outcoded_after }
    it "returns a date 3 days earlier at midnight" do
      is_expected.to eq(Time.zone.local(2015, 1, 29, 0))
    end
  end

  context ".add_establish_claim_data" do
    it "creates EstablishClaim task and it's related meta data'" do
      CreateEstablishClaimTasksJob.new.add_establish_claim_data(@full_grant)
      expect(EstablishClaim.count).to eq(1)
      expect(ClaimEstablishment.count).to eq(1)

      establish_claim = EstablishClaim.first
      expect(establish_claim.appeal_id).to eq(@full_grant.id)
      expect(establish_claim.claim_establishment.outcoding_date).to eq(@full_grant.outcoding_date)
      expect(establish_claim.claim_establishment).to be_full_grant
    end
  end
end
