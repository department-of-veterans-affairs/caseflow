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

  describe "#current_version" do
    fcontext "when there is more than one version of the unrecognized appellant" do
      it "returns a list of versions" do
        current_user = User.last
        ua_detail = create(:unrecognized_party_detail, :individual) 
        # Initial creation of UA
        ua_current = create(:unrecognized_appellant, unrecognized_party_detail: ua_detail)

        expect(ua_current.original_version).to eq ua_current

        ## Begin update process
        # Duplicate the current UA and UA details
        ua_old_version_1 = ua_current.dup
        ua_details_old_version = ua_current.unrecognized_party_detail.dup
        # Point the duplicated version to the current version and link duplicated details
        ua_old_version_1.update(current_version: ua_current, unrecognized_party_detail: ua_details_old_version)
        # Update the current version attributes
        ua_current.unrecognized_party_detail.update(name: "Updated")

        ## Do another update
        ua_old_version_2 = ua_current.dup
        ua_details_old_version = ua_current.unrecognized_party_detail.dup
        ua_old_version_2.update(current_version: ua_current, unrecognized_party_detail: ua_details_old_version)
        ua_current.unrecognized_party_detail.update(name: "Updated Again")

        expect(ua_current.versions.count).to eq 2
        expect(ua_old_version_1.current_version).to eq ua_current
        expect(ua_current.unrecognized_party_detail.name).to eq "Updated Again Smith"
        expect(ua_current.original_version.unrecognized_party_detail.name).to eq "Jane Smith"

        binding.pry
      end
    end
  end
end
