require "ostruct"

describe Dispatch do
  before do
    Fakes::AppealRepository.records = {
      "ABC-1" => Fakes::AppealRepository.appeal_remand_decided
    }
    Timecop.freeze(Time.utc(2017, 1, 1))

    Fakes::AppealRepository.end_product_claim_id = "12345"
  end

  let(:task) {  create_tasks(1).first }
  let(:claim) { {
    poa: "None",
    end_product_code: "172BVAG",
    end_product_label: "BVA Grant",
    end_product_modifier: "170",
    poa_code: "",
    gulf_war_registry: false,
    allow_poa: false,
    suppress_acknowledgement_letter: false

  } }
  let(:dispatch) { Dispatch.new(claim: claim, task: task) }

  context "#claim_valid?" do
    subject { dispatch.claim_valid? }
    it "is true for a claim with proper end_product values" do
      is_expected.to be_truthy
    end

    it "is false for a claim missing end_product_modifier" do
      claim.delete(:end_product_modifier)
      is_expected.to be_falsey
    end

    it "is false for a claim missing end_product_code" do
      claim.delete(:end_product_modifier)
      is_expected.to be_falsey
    end

    it "is false for a claim with mismatched end_product code & label" do
      claim[:end_product_label] = "invalid label"
      is_expected.to be_falsey
    end
  end

  context "#validate_claim!" do
    subject { dispatch.validate_claim! }

    it "throws an error when invalid" do
      claim.delete(:end_product_modifier)
      expect { subject }.to raise_error(Dispatch::InvalidClaimError)
    end

    it "does nothing when valid" do
      expect(dispatch.claim_valid?).to be_truthy
      expect { subject }.to_not raise_error(Dispatch::InvalidClaimError)
    end
  end

  context "#default_claim_values" do
    subject { dispatch.default_claim_values }

    it "returns a hash" do
      is_expected.to be_an_instance_of(Hash)
    end
  end

  context "#dynamic_claim_values" do
    subject { dispatch.dynamic_claim_values }

    it "returns a hash" do
      is_expected.to be_an_instance_of(Hash)
    end

    it "returns a date attr matching the current timestamp" do
      expect(subject[:date]).to eq(Time.now.utc.to_date)
    end
  end

  context "#establish_claim!" do
    it "completes the task" do
      expect(task.complete?).to be_falsey
      dispatch.establish_claim!
      expect(task.reload.complete?).to be_truthy
      expect(task.outgoing_reference_id).to eq("12345")
    end

    it "raises an error if claim is invalid" do
      claim.delete(:end_product_modifier)
      expect(dispatch.claim_valid?).to be_falsey
      expect { dispatch.establish_claim! }.to raise_error(Dispatch::InvalidClaimError)
    end
  end
end
