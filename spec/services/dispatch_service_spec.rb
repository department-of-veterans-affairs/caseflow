require "ostruct"

# Get rid of this function!
def create_tasks(count, opts = {})
  Array.new(count) do |i|
    vacols_id = "#{opts[:id_prefix] || 'ABC'}-#{i}"
    appeal = Appeal.create(vacols_id: vacols_id, vbms_id:  "DEF-#{i}")
    Fakes::AppealRepository.records[vacols_id] = Fakes::AppealRepository.appeal_remand_decided

    user = User.create(station_id: "123", css_id: "#{opts[:id_prefix] || 'ABC'}-#{i}", full_name: "Jane Smith #{i}")
    task = EstablishClaim.create(appeal: appeal)
    task.prepare!
    task.assign!(:assigned, user)

    task.start! if %i(started reviewed completed).include?(opts[:initial_state])
    task.review!(outgoing_reference_id: "123") if %i(reviewed completed).include?(opts[:initial_state])
    task.complete!(:completed, status: 0) if %i(completed).include?(opts[:initial_state])
    task
  end
end

describe Dispatch do
  before do
    Fakes::AppealRepository.records = {
      "ABC-1" => Fakes::AppealRepository.appeal_remand_decided
    }
    Timecop.freeze(Time.utc(2017, 1, 1))

    Fakes::AppealRepository.end_product_claim_id = "12345"
  end

  let(:task) { create_tasks(1).first }
  let(:user) { User.create(station_id: "ABC", css_id: "123") }
  let(:claim) do
    {
      date: "03/03/2017",
      end_product_code: "172BVAG",
      end_product_label: "BVA Grant",
      end_product_modifier: "170",
      gulf_war_registry: false,
      suppress_acknowledgement_letter: false,
      station_of_jurisdiction: "499"
    }
  end

  let(:vacols_note) { nil }
  let(:dispatch) { Dispatch.new(claim: claim, task: task, vacols_note: vacols_note) }

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
    it "moves the task to review" do
      task.start!
      expect(task.completed?).to be_falsey
      dispatch.establish_claim!
      expect(task.reload.reviewed?).to be_truthy
      expect(task.outgoing_reference_id).to eq("12345")
    end

    it "raises an error if claim is invalid" do
      claim.delete(:end_product_modifier)
      expect(dispatch.claim.valid?).to be_falsey
      expect { dispatch.establish_claim! }.to raise_error(Dispatch::InvalidClaimError)
    end

    context "when VBMS throws an EP already exists error" do
      let(:ep_already_exists_error) do
        VBMS::HTTPError.new("500", "<faultstring>Claim not established. " \
          "A duplicate claim for this EP code already exists in CorpDB. Please " \
          "use a different EP code modifier. GUID: 13fcd</faultstring>")
      end

      it "raises EndProductAlreadyExistsError" do
        allow(Appeal.repository).to receive(:establish_claim!).and_raise(ep_already_exists_error)

        expect do
          dispatch.establish_claim!
        end.to raise_error(Dispatch::EndProductAlreadyExistsError)
      end
    end

    context "when VBMS throws an EP already exists in BGS error" do
      let(:ep_already_exists_error) do
        VBMS::HTTPError.new("500", "<faultstring>Claim not established." \
          " BGS code; PIF is already in use.</faultstring>")
      end

      it "raises EndProductAlreadyExistsError" do
        allow(Appeal.repository).to receive(:establish_claim!).and_raise(ep_already_exists_error)

        expect do
          dispatch.establish_claim!
        end.to raise_error(Dispatch::EndProductAlreadyExistsError)
      end
    end

    context "when VBMS throws an unrecognized error" do
      let(:unrecognized_error) do
        VBMS::HTTPError.new("500", "<faultstring>some error</faultstring>")
      end

      it "Re-raises the error" do
        allow(Appeal.repository).to receive(:establish_claim!).and_raise(unrecognized_error)

        expect do
          dispatch.establish_claim!
        end.to raise_error(VBMS::HTTPError)
      end
    end
  end

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
end
