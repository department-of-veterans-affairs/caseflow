# frozen_string_literal: true

describe OtherClaimant, :postgres do
  let(:claimant) { create(:claimant, type: "OtherClaimant") }

  describe "#save_unrecognized_details!" do
    let(:params) do
      ActionController::Parameters.new(
        relationship: relationship,
        party_type: party_type,
        address_line_1: "1600 Pennsylvania Ave",
        city: "Springfield",
        state: "NY",
        zip: "12345",
        country: "USA",
        poa_form: false
      )
    end

    subject { claimant.save_unrecognized_details!(params) }

    context "when appellant is an unlisted individual" do
      let(:relationship) { "child" }
      let(:party_type) { "individual" }
      it "saves the individual" do
        params[:first_name] = "John"
        params[:last_name] = "Smith"

        expect(subject).to have_attributes(
          name: "John Smith",
          relationship: "child"
        )
        expect(subject.unrecognized_party_detail).to have_attributes(
          party_type: "person",
          name: "John Smith"
        )
      end
    end

    context "when appellant is an unlisted organization" do
      let(:relationship) { "attorney" }
      let(:party_type) { "organization" }
      it "saves the organization" do
        params[:name] = "American Legion"

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
  end
end
