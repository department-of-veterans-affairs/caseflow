describe RampElectionRollback do
  before do
    FeatureToggle.enable!(:test_facols)
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  let(:established_end_product) do
    EndProductEstablishment.create(
      veteran_file_number: "44444444",
      source: ramp_election,
      reference_id: "EP1234",
      last_synced_at: 2.days.ago,
      synced_status: ep_status
    )
    # Generators::EndProduct.build(
    #   veteran_file_number: "44444444",
    #   bgs_attrs: {
    #     benefit_claim_id: "EP1234",
    #     status_type_code: ep_status
    #   }
    # )
  end

  let!(:ramp_election) do
    create(:ramp_election,
           veteran_file_number: "44444444",
           option_selected: "higher_level_review",
           receipt_date: 5.days.ago)
  end

  let(:rollback) do
    RampElectionRollback.new(
      ramp_election: ramp_election,
      user: user,
      reason: reason
    )
  end

  let(:user) { Generators::User.build }
  let(:reason) { "A very good reason" }

  let(:ep_status) { "CAN" }

  context "#valid?" do
    subject { rollback.valid? }

    it do
      established_end_product
      is_expected.to be true
    end

    context "when no ramp election" do
      let(:ramp_election) { nil }

      it { is_expected.to be false }
    end

    context "when no user" do
      let(:user) { nil }

      it { is_expected.to be false }
    end

    context "when no reason" do
      let(:reason) { nil }

      it { is_expected.to be false }
    end

    context "when end product isn't canceled" do
      let(:ep_status) { "PEND" }

      it { is_expected.to be false }
    end
  end

  context "#create!" do
    subject { rollback.save! }

    before { established_end_product }

    let!(:appeals_to_reopen) do
      %w[12345 23456].map do |vacols_id|
        ramp_election.ramp_closed_appeals.create!(vacols_id: vacols_id)
        create(:legacy_appeal,
               vacols_case: create(
                 :case_with_decision,
                 :type_original,
                 :status_complete,
                 :disposition_ramp,
                 bfboard: "00",
                 bfkey: vacols_id
               ))
      end
    end

    it "reopens appeals and rolls back ramp election" do
      expect(LegacyAppeal).to receive(:reopen).with(
        appeals: appeals_to_reopen,
        user: user,
        disposition: "RAMP Opt-in"
      )

      subject

      expect(ramp_election.reload.end_product_reference_id).to eq(nil)
      expect(rollback.reload.reopened_vacols_ids).to eq(%w[12345 23456])
    end
  end
end
