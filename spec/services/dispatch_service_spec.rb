require "ostruct"

describe Dispatch do
  before do
    Timecop.freeze(Time.utc(2017, 1, 1))
  end

  let(:claim) do
    {
      date: "03/03/2017",
      end_product_code: "172BVAG",
      end_product_label: "BVA Grant",
      end_product_modifier: claim_modifier,
      gulf_war_registry: false,
      suppress_acknowledgement_letter: false,
      station_of_jurisdiction: "499"
    }
  end

  let(:task_state) { :unprepared }
  let(:claim_modifier) { "170" }
  let(:vacols_note) { nil }

  let(:task) { Generators::EstablishClaim.create(aasm_state: task_state) }
  let(:dispatch) { Dispatch.new(claim: claim, task: task, vacols_note: vacols_note) }

  context ".new" do
    context "when vacols_note is > 280" do
      let(:vacols_note) { "abc" * 100 } # 300 length
      it "truncates vacols_note to 280" do
        expect(dispatch.vacols_note.length).to eq(280)
      end
    end

    context "when vacols_note is nil" do
      let(:vacols_note) { nil }
      it "is still nil" do
        expect(dispatch.vacols_note).to eq(nil)
      end
    end
  end

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
end
