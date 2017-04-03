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
      modifier: modifier
    )
  end

  let(:claim_type_code) { nil }
  let(:status_type_code) { nil }
  let(:modifier) { nil }
  let(:claim_date) { Time.zone.now }

  context "#claim_type" do
    subject { end_product.claim_type }

    context "when claim type code is recognized" do
      let(:claim_type_code) { "170RMDAMC" }
      it { is_expected.to eq("ARC-Remand") }
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
      let(:modifier) { "170" }

      context "when active" do
        let(:status_type_code) { "PEND" }
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

      context "when active" do
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

      context "when not active" do
        let(:status_type_code) { "CAN" }
        it { is_expected.to be_falsey }
      end
    end

    context "when it doesn't have a dispatch code" do
      let(:status_type_code) { "PEND" }
      it { is_expected.to be_falsey }

      context "when it has a full grant modifier" do
        let(:modifier) { "172" }
        it { is_expected.to be_truthy }
      end
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
      ).serializable_hash
    end

    it "serializes the hash correctly" do
      expect(result).to eq(benefit_claim_id: "SHAQ123",
                           claim_receive_date: "09/06/2017",
                           claim_type_code: "Grant of Benefits",
                           end_product_type_code: "172",
                           status_type_code: "Pending")
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
end
