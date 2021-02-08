# frozen_string_literal: true

describe OtherClaimant, :postgres do
  let(:claimant) { create(:claimant, type: "OtherClaimant") }
  let(:first_name) { nil }
  let(:last_name) { nil }
  let(:name) { nil }

  describe "#save_unrecognized_details!" do
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
        poa_form: false
      )
    end

    subject { claimant.save_unrecognized_details!(params) }

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
  end
end
