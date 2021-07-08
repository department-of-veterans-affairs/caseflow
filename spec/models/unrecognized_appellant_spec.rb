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
    context "when there is only one version of the unrecognized appellant" do
      it "returns itself when there is no previous versions" do
        ua_detail = create(:unrecognized_party_detail, :individual)
        # Initial creation of UA
        ua_current = create(:unrecognized_appellant, unrecognized_party_detail: ua_detail)

        expect(ua_current.first_version).to eq ua_current
      end
    end
    context "when there is more than one version of the unrecognized appellant" do
      it "returns a list of versions" do
        ua_detail = create(:unrecognized_party_detail, :individual)
        # Initial creation of UA
        ua_current = create(:unrecognized_appellant, unrecognized_party_detail: ua_detail)
        ua_current.update(current_version: ua_current)

        expect(ua_current.first_version).to eq ua_current

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

        # Should have 3 versions: original + 2 updates
        expect(ua_current.versions.count).to eq 3

        # Any old version .current_version should be the current version
        expect(ua_old_version_1.current_version).to eq ua_current
        expect(ua_old_version_2.current_version).to eq ua_current

        # Current version should be the second updated value
        expect(ua_current.unrecognized_party_detail.name).to eq "Updated Again Smith"

        # Ensure original versions are all the value we started at
        expect(ua_current.first_version.unrecognized_party_detail.name).to eq "Jane Smith"
        expect(ua_current.versions.second.first_version.unrecognized_party_detail.name).to eq "Jane Smith"

        # Ensure claimant relationship is accurate
        claimant = ua_current.first_version.claimant
        expect(claimant.unrecognized_appellant).to eq ua_current
      end
    end
  end
  describe "update_with_versioning!" do
    context "when unrecognized_appellant is updated" do
      let(:user) { User.first }
      let(:update_params) do
        {
          relationship: "updated",
          unrecognized_party_detail: {
            address_line_1: "updated_address_1",
            address_line_2: "updated_address_2"
          }
        }
      end
      it "updates the unrecognized appellant and creates a new version" do
        ua_detail = create(:unrecognized_party_detail, :individual)
        ua_current = create(:unrecognized_appellant, unrecognized_party_detail: ua_detail)

        ua_current.update_with_versioning!(update_params, user)

        expect(ua_current.relationship).to eq update_params[:relationship]
        expect(ua_current.versions.length).to eq 2
      end
    end
  end
end
