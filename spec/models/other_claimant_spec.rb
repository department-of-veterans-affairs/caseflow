# frozen_string_literal: true

describe OtherClaimant, :postgres do
  describe "#save_unrecognized_details!" do
    let(:claimant) { create(:claimant, type: "OtherClaimant") }
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

    subject { claimant.save_unrecognized_details!(params, poa_params, poa_participant_id) }

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

    context "when unlisted POA is given" do
      let(:poa_params) do
        ActionController::Parameters.new(
          party_type: "organization",
          name: "POA Name",
          address_line_1: "123 1st Cir",
          city: "Springfield",
          state: "AL",
          zip: "54321",
          country: "USA"
        )
      end

      it "saves the unlisted POA" do
        expect(subject.unrecognized_power_of_attorney).to have_attributes(
          party_type: "organization",
          name: "POA Name"
        )
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
  end
end
