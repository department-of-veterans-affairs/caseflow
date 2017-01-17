require "ostruct"

describe Dispatch do
  before do
    Fakes::AppealRepository.records = {
      "ABC-1" => Fakes::AppealRepository.appeal_remand_decided
    }
    Timecop.freeze(Time.utc(2017, 1, 1))

    Fakes::AppealRepository.end_product_claim_id = "12345"
  end

  let(:task) { create_tasks(1).first }
  let(:claim) do
    {
      poa: "None",
      date: "03/03/2017",
      end_product_code: "172BVAG",
      end_product_label: "BVA Grant",
      end_product_modifier: "170",
      poa_code: "",
      gulf_war_registry: false,
      allow_poa: false,
      suppress_acknowledgement_letter: false

    }
  end
  let(:dispatch) { Dispatch.new(claim: claim, task: task) }

  describe Dispatch::Claim do
    context "#valid?" do
      subject { dispatch.claim.valid? }
      it "is true for a claim with proper end_product values" do
        is_expected.to be_truthy
      end

      it "is false for a claim missing end_product_modifier" do
        claim.delete(:end_product_modifier)
        is_expected.to be_falsey
        expect(dispatch.claim.errors.keys).to include(:end_product_modifier)
      end

      it "is false for a claim missing end_product_code" do
        claim.delete(:end_product_modifier)
        is_expected.to be_falsey
        expect(dispatch.claim.errors.keys).to include(:end_product_modifier)
      end

      it "is false for a claim with mismatched end_product code & label" do
        claim[:end_product_label] = "invalid label"
        is_expected.to be_falsey
        expect(dispatch.claim.errors.keys).to include(:end_product_label)
      end
    end

    context "#dynamic_values" do
      subject { dispatch.claim.dynamic_values }

      it "returns a hash" do
        is_expected.to be_an_instance_of(Hash)
      end
    end

    context "#formatted_date" do
      subject { dispatch.claim.formatted_date }
      it "returns a date object" do
        is_expected.to be_an_instance_of(Date)
      end
    end

    context "#to_hash" do
      subject { dispatch.claim.to_hash }
      it "returns a hash" do
        is_expected.to be_an_instance_of(Hash)
      end

      it "includes default_values" do
        is_expected.to include(:benefit_type_code)
      end

      it "includes dynamic_values" do
        is_expected.to include(:date)
      end

      it "includes variable values" do
        is_expected.to include(:end_product_code)
      end
    end
  end

  context "#validate_claim!" do
    subject { dispatch.validate_claim! }

    it "throws an error when invalid" do
      claim.delete(:end_product_modifier)
      expect { subject }.to raise_error(Dispatch::InvalidClaimError)
    end

    it "does nothing when valid" do
      expect(dispatch.claim.valid?).to be_truthy
      expect { subject }.to_not raise_error(Dispatch::InvalidClaimError)
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
      expect(dispatch.claim.valid?).to be_falsey
      expect { dispatch.establish_claim! }.to raise_error(Dispatch::InvalidClaimError)
    end
  end

  context "#filter_dispatch_end_products" do
    let(:end_products) do
      [{ claim_type_code: "170APPACT" },
       { claim_type_code: "170APPACTPMC" },
       { claim_type_code: "170PGAMC" },
       { claim_type_code: "170RMD" },
       { claim_type_code: "170RMDAMC" },
       { claim_type_code: "170RMDPMC" },
       { claim_type_code: "172GRANT" },
       { claim_type_code: "172BVAG" },
       { claim_type_code: "172BVAGPMC" },
       { claim_type_code: "400CORRC" },
       { claim_type_code: "400CORRCPMC" },
       { claim_type_code: "930RC" },
       { claim_type_code: "930RCPMC" }]
    end

    let(:extra_end_products) do
      end_products.clone.push(claim_type_code: "Test")
    end

    subject { Dispatch.filter_dispatch_end_products(extra_end_products) }

    it "filters out non-dispatch end products" do
      is_expected.to eq(end_products)
    end
  end
end
