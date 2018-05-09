describe RampElectionRollback do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let!(:ramp_election) do
    RampElection.create!(
      veteran_file_number: "44444444",
      option_selected: "higher_level_review",
      receipt_date: 5.days.ago,
      end_product_reference_id: "EP1234"
    )
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

  let!(:established_end_product) do
    Generators::EndProduct.build(
      veteran_file_number: "44444444",
      bgs_attrs: {
        benefit_claim_id: "EP1234",
        status_type_code: ep_status
      }
    )
  end

  let(:ep_status) { "CAN" }

  context "#valid?" do
    subject { rollback.valid? }

    it { is_expected.to be true }

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

    let!(:appeals_to_reopen) do
      %w[12345 23456].map do |vacols_id|
        ramp_election.ramp_closed_appeals.create!(vacols_id: vacols_id)
        Generators::LegacyAppeal.create(vacols_record: :ramp_closed, vacols_id: vacols_id)
      end
    end

    it "reopens appeals and rolls back ramp election" do
      expect(Appeal).to receive(:reopen).with(
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
