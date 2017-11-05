require "rails_helper"

describe EndProduct do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:end_product) do
    EndProduct.new(
      claim_date: claim_date,
      claim_type_code: claim_type_code,
      status_type_code: status_type_code,
      modifier: modifier,
      station_of_jurisdiction: station_of_jurisdiction,
      gulf_war_registry: gulf_war_registry,
      suppress_acknowledgement_letter: suppress_acknowledgement_letter
    )
  end

  let(:claim_type_code) { nil }
  let(:status_type_code) { nil }
  let(:modifier) { nil }
  let(:claim_date) { Time.zone.now }
  let(:station_of_jurisdiction) { "489" }
  let(:gulf_war_registry) { false }
  let(:suppress_acknowledgement_letter) { true }

  context "#claim_type" do
    subject { end_product.claim_type }

    context "when claim type code is recognized" do
      let(:claim_type_code) { "070BVAGR" }
      it { is_expected.to eq("BVA Grant (070)") }
    end

    context "when claim type code is unrecognized" do
      let(:claim_type_code) { "SHAQ4EVER" }
      it { is_expected.to eq("SHAQ4EVER") }
    end
  end

  context "#status_type" do
    subject { end_product.status_type }

    context "when status type code is recognized" do
      let(:status_type_code) { "CLR" }
      it { is_expected.to eq("Cleared") }
    end

    context "when claim type code is unrecognized" do
      let(:status_type_code) { "SHAQ4EVER" }
      it { is_expected.to eq("SHAQ4EVER") }
    end
  end

  context "#dispatch_conflict?" do
    subject { end_product.dispatch_conflict? }

    context "when modifier is a dispatch modifier" do
      let(:modifier) { "070" }

      context "when active" do
        let(:status_type_code) { "RFD" }
        it { is_expected.to be_truthy }
      end

      context "when not active" do
        let(:status_type_code) { "CAN" }
        it { is_expected.to be_falsey }
      end
    end

    context "when modifier isn't dispatch modifier" do
      let(:modifier) { "180" }
      let(:status_type_code) { "PEND" }
      it { is_expected.to be_falsey }
    end
  end

  context "#potential_match?" do
    let(:appeal) { Appeal.new(decision_date: Time.zone.now) }
    subject { end_product.potential_match?(appeal) }

    context "when it has a dispatch code" do
      let(:claim_type_code) { "170RMDAMC" }

      context "when assignable" do
        let(:status_type_code) { "PEND" }

        context "when claim date is 29 days ahead of the decision date" do
          let(:claim_date) { 29.days.from_now }
          it { is_expected.to be_truthy }
        end

        context "when claim date is 29 days before the decision date" do
          let(:claim_date) { 29.days.ago }
          it { is_expected.to be_truthy }
        end

        context "when claim date is 31 days ahead of the decision date" do
          let(:claim_date) { 31.days.from_now }
          it { is_expected.to be_falsey }
        end

        context "when claim date is 31 days before the decision date" do
          let(:claim_date) { 31.days.ago }
          it { is_expected.to be_falsey }
        end
      end

      context "when not assignable" do
        let(:status_type_code) { "CAN" }
        it { is_expected.to be_falsey }
      end
    end

    context "when it doesn't have a dispatch code" do
      let(:status_type_code) { "PEND" }
      it { is_expected.to be_falsey }
    end
  end

  context "#valid?" do
    subject { end_product.valid? }

    let(:modifier) { "170" }
    let(:claim_type_code) { "400CORRCPMC" }
    let(:station_of_jurisdiction) { "489" }
    let(:gulf_war_registry) { false }
    let(:suppress_acknowledgement_letter) { true }

    it { is_expected.to be_truthy }

    context "when modifier is missing" do
      let(:modifier) { nil }
      it { is_expected.to be_falsey }
    end

    context "when claim_type_code is missing" do
      let(:claim_type_code) { nil }
      it { is_expected.to be_falsey }
    end

    context "when claim_type_code is invalid" do
      let(:claim_type_code) { "WHATWHO" }
      it { is_expected.to be_falsey }
    end

    context "when station_of_jurisdiction is missing" do
      let(:station_of_jurisdiction) { nil }
      it { is_expected.to be_falsey }
    end

    context "when claim_date is missing" do
      let(:claim_date) { nil }
      it { is_expected.to be_falsey }
    end

    context "when gulf_war_registry is not a boolean" do
      let(:gulf_war_registry) { "shane" }
      it { is_expected.to be_falsey }
    end

    context "when suppress_acknowledgement_letter is not a boolean" do
      let(:suppress_acknowledgement_letter) { "shane" }
      it { is_expected.to be_falsey }
    end
  end

  context "#serializable_hash" do
    let(:result) do
      EndProduct.new(
        claim_id: "SHAQ123",
        claim_type_code: "172GRANT",
        status_type_code: "PEND",
        modifier: "172",
        claim_date: Time.zone.local(2017, 9, 6, 10, 10, 1)
      ).serializable_hash({})
    end

    it "serializes the hash correctly" do
      expect(result).to eq(
        benefit_claim_id: "SHAQ123",
        claim_receive_date: "09/06/2017",
        claim_type_code: "Grant of Benefits",
        end_product_type_code: "172",
        status_type_code: "Pending"
      )
    end
  end

  context "#description" do
    subject { end_product.description }

    context "when ep_code doesn't exist" do
      let(:claim_type_code) { "BLARGYBLARG" }
      it { is_expected.to be_nil }
    end

    context "when ep_code does exist" do
      let(:claim_type_code) { "170RBVAG" }
      it { is_expected.to eq("170RBVAG - Remand with BVA Grant") }
    end
  end

  context "#to_vbms_hash" do
    subject { end_product.to_vbms_hash }

    let(:modifier) { "170" }
    let(:claim_type_code) { "930RC" }
    let(:station_of_jurisdiction) { "313" }
    let(:gulf_war_registry) { true }
    let(:suppress_acknowledgement_letter) { false }
    let(:claim_date) { 7.days.from_now }

    it "maps attributes correctly" do
      is_expected.to eq(
        benefit_type_code: "1",
        payee_code: "00",
        predischarge: false,
        claim_type: "Claim",
        end_product_modifier: "170",
        end_product_code: "930RC",
        end_product_label: "Rating Control",
        station_of_jurisdiction: "313",
        date: 7.days.from_now.to_date,
        suppress_acknowledgement_letter: false,
        gulf_war_registry: true
      )
    end
  end

  context ".from_bgs_hash" do
    let(:result) { EndProduct.from_bgs_hash(bgs_hash) }
    let(:bgs_hash) do
      {
        benefit_claim_id: "2",
        claim_receive_date: 10.days.from_now.to_formatted_s(:short_date),
        claim_type_code: "170RMD",
        end_product_type_code: "170",
        status_type_code: "PEND"
      }
    end

    it "maps attributes correctly" do
      expect(result).to have_attributes(
        claim_id: "2",
        claim_date: 10.days.from_now.beginning_of_day,
        claim_type_code: "170RMD",
        modifier: "170",
        status_type_code: "PEND"
      )
    end
  end

  context ".from_establish_claim_params" do
    subject { EndProduct.from_establish_claim_params(params) }

    let(:params) do
      {
        date: 14.days.from_now.to_formatted_s(:short_date),
        end_product_code: "172BVAG",
        end_product_modifier: "170",
        gulf_war_registry: true,
        suppress_acknowledgement_letter: true,
        station_of_jurisdiction: "499"
      }
    end

    it "maps attributes correctly" do
      is_expected.to have_attributes(
        claim_date: 14.days.from_now.beginning_of_day,
        claim_type_code: "172BVAG",
        claim_type: "BVA Grant",
        modifier: "170",
        gulf_war_registry: true,
        suppress_acknowledgement_letter: true,
        station_of_jurisdiction: "499"
      )
    end
  end
end
