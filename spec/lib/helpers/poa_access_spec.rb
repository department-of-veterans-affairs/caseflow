# frozen_string_literal: true

require "helpers/poa_access"

describe "WarRoom::PoaAccess" do
  let!(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
  let!(:poa) { create(:bgs_power_of_attorney) }

  context "when run against a legacy appeal" do
    it "creates a person record" do
      # To avoid adding to the large amount of dummy data lets just coerce the record to be :not_found
      allow_any_instance_of(BgsPowerOfAttorney).to receive(:bgs_record).and_return(:not_found)

      expect(Person).to receive(:find_or_create_by_participant_id).with(poa.claimant_participant_id)

      expect(BgsPowerOfAttorney).to receive(:find_or_create_by_claimant_participant_id)
        .with(poa.claimant_participant_id)
        .and_return(poa)

      remediation_success = WarRoom::PoaAccess.new(legacy_appeal.vacols_id, poa.claimant_participant_id).run

      expect(remediation_success).to be true
    end
  end
end
