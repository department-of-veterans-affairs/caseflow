# frozen_string_literal: true

describe RampElectionRollback, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2019, 1, 1, 12, 0, 0))
  end

  let(:established_end_product) do
    ep = Generators::EndProduct.build(
      veteran_file_number: "44444444",
      bgs_attrs: {
        benefit_claim_id: "EP1234",
        status_type_code: ep_status
      }
    )
    create(
      :end_product_establishment,
      veteran_file_number: "44444444",
      source: ramp_election,
      last_synced_at: 2.days.ago,
      synced_status: ep_status,
      reference_id: ep.claim_id
    )
  end

  let!(:ramp_election) do
    create(:ramp_election,
           veteran_file_number: "44444444",
           option_selected: "higher_level_review",
           receipt_date: 5.days.ago)
  end

  let!(:ramp_issue) do
    RampIssue.new(
      review_type: ramp_election,
      contention_reference_id: "1234",
      description: "description",
      source_issue_id: "12345"
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

    let!(:appeal_already_open) do
      ramp_election.ramp_closed_appeals.create!(vacols_id: "34567")

      create(
        :legacy_appeal,
        vacols_case: create(
          :case_with_soc,
          :type_original,
          bfboard: "00",
          bfkey: "34567"
        )
      )
    end

    it "reopens appeals and rolls back ramp election" do
      expect(LegacyAppeal).to receive(:reopen).with(
        appeals: appeals_to_reopen,
        user: user,
        disposition: "RAMP Opt-in"
      )

      subject

      resultant_end_product_establishment = EndProductEstablishment.find_by(source: ramp_election)
      expect(resultant_end_product_establishment).to eq(nil)
      expect(rollback.reload.reopened_vacols_ids).to eq(%w[12345 23456])
      expect { ramp_issue.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
