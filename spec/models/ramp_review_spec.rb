# frozen_string_literal: true

describe RampReview, :postgres do
  let(:ramp_election) { create(:ramp_election, option_selected: "higher_level_review", established_at: Time.zone.now) }
  let(:claim_date) { ramp_election.receipt_date.to_date.mdY }
  let(:reference_id) { nil }
  let(:end_product_status) { nil }
  let(:last_action_date) { nil }

  let(:modifier) { "682" }
  let(:claim_type_code) { "682HLRRRAMP" }

  let!(:end_product) do
    Generators::EndProduct.build(
      veteran_file_number: ramp_election.veteran_file_number,
      bgs_attrs: {
        claim_type_code: claim_type_code,
        end_product_type_code: modifier,
        claim_receive_date: claim_date,
        status_type_code: end_product_status,
        last_action_date: last_action_date
      }
    )
  end

  context "#end_product_active?" do
    subject { ramp_election.end_product_active? }

    context "when the end_product_establishment can sync" do
      let(:reference_id) { end_product.claim_id }
      let!(:end_product_establishment) do
        create(
          :end_product_establishment,
          source: ramp_election,
          reference_id: reference_id,
          veteran_file_number: ramp_election.veteran_file_number,
          synced_status: end_product_status
        )
      end

      context "when the end product is inactive" do
        let(:end_product_status) { "CLR" }

        it { is_expected.to eq(false) }
      end

      context "when the end product is active" do
        let(:end_product_status) { "PEND" }

        it { is_expected.to eq(true) }
      end
    end

    context "when there is no EPE and all preexisting EPs are inactive" do
      context "all preexisting end products are inactive" do
        let(:end_product_status) { "CLR" }

        it { is_expected.to eq(false) }
      end

      context "one preexisting end product is active" do
        let(:end_product_status) { "PEND" }

        it { is_expected.to eq(true) }
      end
    end
  end
end
