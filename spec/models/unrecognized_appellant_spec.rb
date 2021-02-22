# frozen_string_literal: true

describe UnrecognizedAppellant do
  let(:poa_detail) { nil }

  describe "#power_of_attorney" do
    let(:ua) { create(:unrecognized_appellant, unrecognized_power_of_attorney: poa_detail) }
    subject { ua.power_of_attorney }

    context "when there is an unrecognized POA" do
      let(:poa_detail) { create(:unrecognized_party_detail, :individual) }

      it "returns a POA object with the correct attributes" do
        expect(subject).to have_attributes(
          first_name: "Jane",
          last_name: "Smith",
          representative_name: "Jane Smith"
        )
      end
    end

    context "when there is no POA" do
      it { is_expected.to be_nil }
    end
  end
end
