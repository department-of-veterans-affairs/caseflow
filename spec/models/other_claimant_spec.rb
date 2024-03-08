# frozen_string_literal: true

describe OtherClaimant, :postgres do
  let(:claimant) { create(:claimant, type: "OtherClaimant") }

  describe "#save_unrecognized_details!" do
    let(:first_name) { "John" }
    let(:last_name) { nil }
    let(:name) { nil }
    let(:relationship) { "spouse" }
    let(:party_type) { "individual" }
    let(:params) do
      ActionController::Parameters.new(
        relationship: relationship,
        party_type: party_type,
        first_name: first_name,
        last_name: last_name,
        name: name,
        address_line_1: "1600 Pennsylvania Ave",
        city: "Springfield",
        state: "NY",
        zip: "12345",
        country: "USA",
        poa_form: poa_params.present? || poa_participant_id.present?
      )
    end
    let(:poa_params) { nil }
    let(:poa_participant_id) { nil }
    let(:user) { create(:user) }
    let(:benefit_type) { nil }

    before do
      RequestStore[:current_user] = user
    end

    subject { claimant.save_unrecognized_details!(params, poa_params, benefit_type) }

    context "when appellant is an unlisted individual" do
      let(:relationship) { "child" }
      let(:party_type) { "individual" }
      let(:first_name) { "John" }
      let(:last_name) { "Smith" }

      it "saves the individual" do
        expect(subject).to have_attributes(
          name: "John Smith",
          relationship: "child"
        )
        expect(subject.unrecognized_party_detail).to have_attributes(
          party_type: "individual",
          name: "John Smith"
        )
        expect(subject.current_version).to eq subject
        expect(subject.created_by).to eq user
      end
    end

    context "when appellant is an unlisted organization" do
      let(:relationship) { "attorney" }
      let(:party_type) { "organization" }
      let(:name) { "American Legion" }

      it "saves the organization" do
        expect(subject).to have_attributes(
          name: "American Legion",
          relationship: "attorney"
        )
        expect(subject.unrecognized_party_detail).to have_attributes(
          party_type: "organization",
          name: "American Legion"
        )
      end
    end

    context "when an unrecognized appellant has a power of attorney added" do
      let(:poa_params) do
        ActionController::Parameters.new(
          party_type: "organization",
          name: "POA Name",
          address_line_1: "123 1st Cir",
          city: "Springfield",
          state: "AL",
          zip: "54321",
          country: "USA",
          listed_attorney: { value: poa_participant_id }
        )
      end

      context "when unlisted POA is given" do
        let(:poa_participant_id) { "not_listed" }

        it "saves the unlisted POA" do
          expect(subject.unrecognized_power_of_attorney).to have_attributes(
            party_type: "organization",
            name: "POA Name"
          )
          expect(subject.poa_participant_id).to be_nil
        end
      end

      context "when unlisted POA is given" do
        let(:poa_participant_id) { "not_listed" }
        let(:benefit_type) { "vha" }

        it "creates not listed POA object" do
          expect(subject.not_listed_power_of_attorney).to be_present
          expect(subject.unrecognized_power_of_attorney).to be_nil
          expect(subject.poa_participant_id).to be_nil
        end
      end

      context "when CorpDB POA is given" do
        let(:poa_participant_id) { "13579" }

        it "saves the CorpDB POA" do
          expect(subject.poa_participant_id).to eq(poa_participant_id)
          expect(subject.unrecognized_power_of_attorney).to be_nil
        end
      end

      context "when CorpDB Attorney Power of Attorney is given" do
        let(:poa_participant_id) { "6000044" }
        let(:name) { "Generic Attorney, Esq." }
        let!(:bgs_attorney) do
          BgsAttorney.create!(participant_id: poa_participant_id, name: name, record_type: "POA State Organization")
        end

        it "saves the CorpDB APOA" do
          expect(subject.power_of_attorney.name).to eq(name)
          expect(subject.power_of_attorney.bgs_attorney).to_not be_nil
          expect(subject.power_of_attorney.address).to_not be_nil
        end
      end
    end
  end

  describe "#representative_type" do
    let(:atty) { create(:bgs_attorney, record_type: "POA Agent") }
    let!(:unrecognized_appellant) do
      create(:unrecognized_appellant, claimant: claimant, poa_participant_id: atty.participant_id)
    end

    subject { claimant.representative_type }

    it "returns the correct type for a known representative" do
      expect(subject).to eq("Agent")
    end
  end

  describe "#advanced_on_docket_motion_granted?" do
    let(:appeal) { claimant.decision_review }

    subject { claimant.advanced_on_docket_motion_granted?(appeal) }

    it "returns whether an AOD has been granted" do
      AdvanceOnDocketMotion.create_or_update_by_appeal(appeal, granted: true, reason: "age")
      expect(subject).to be_truthy
    end
  end

  describe "#unrecognized_claimant?" do
    subject { claimant.unrecognized_claimant? }

    it "OtherClaimant is considered an unrecognized claimant" do
      is_expected.to eq true
    end
  end
end
