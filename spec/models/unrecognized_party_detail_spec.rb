# frozen_string_literal: true

describe UnrecognizedPartyDetail do
  let(:party_type) { :individual }
  let(:detail) { create(:unrecognized_party_detail, party_type) }

  describe "#name" do
    subject { detail.name }

    context "when the party is an individual" do
      it { is_expected.to eq "Jane Smith" }
    end

    context "when the party is an organization" do
      let(:party_type) { :organization }
      it { is_expected.to eq "Steinberg and Sons" }
    end
  end

  describe "#first_name" do
    subject { detail.first_name }

    context "when the party is an individual" do
      it { is_expected.to eq "Jane" }
    end

    context "when the party is an organization" do
      let(:party_type) { :organization }
      it { is_expected.to be_nil }
    end
  end

  describe "#address" do
    subject { detail.address }

    it "returns the full address as a hash" do
      expect(subject).to include(
        address_line_1: "123 Park Ave",
        address_line_2: nil,
        address_line_3: nil,
        city: "Springfield",
        state: "NY",
        zip: "12345",
        country: "USA"
      )
    end
  end
end
