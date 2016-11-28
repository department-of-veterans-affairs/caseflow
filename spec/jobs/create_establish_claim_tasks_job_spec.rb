describe CreateEstablishClaimTasksJob do
  before do
    reset_application!

    @partial_grant = Fakes::AppealRepository.new("123C", :appeal_remand_decided)
    @full_grant = Fakes::AppealRepository.new("456D", :appeal_full_grant_decided, decision_date: 1.day.ago)

    allow(AppealRepository).to receive(:remands_ready_for_claims_establishment).and_return([@partial_grant])
    allow(AppealRepository).to receive(:amc_full_grants).and_return([@full_grant])
    Timecop.freeze(Time.zone.local(2015, 1, 10, 12, 8, 0))
  end

  after { Timecop.return }

  context ".perform" do
    it "finds or creates tasks" do
      expect(EstablishClaim.count).to eq(0)
      CreateEstablishClaimTasksJob.perform_now
      expect(EstablishClaim.count).to eq(2)

      # on re-run, the same 2 appeals should be found
      # so no new tasks are created
      CreateEstablishClaimTasksJob.perform_now
      expect(EstablishClaim.count).to eq(2)
    end

  end

  context ".full_grant_decided_after" do
    subject { CreateEstablishClaimTasksJob.new.full_grant_decided_after }
    it "returns a date 3 days earlier at midnight" do
      is_expected.to eq(Time.zone.local(2015, 1, 7, 0))
    end
  end
end
