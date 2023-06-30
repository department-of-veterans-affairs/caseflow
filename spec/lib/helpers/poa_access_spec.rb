# frozen_string_literal: true

require "helpers/poa_access"

describe "WarRoom::PoaAccess" do
  let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
  let(:poa) { create(:bgs_power_of_attorney) }

  context "when run against a legacy appeal" do
    subject { WarRoom::PoaAccess.new(appeal.vacols_id, poa.claimant_participant_id).run }
    it "creates a person record for spouse when poa :not_found" do
      # To avoid adding to the large amount of dummy data lets just coerce the record to be :not_found
      allow_any_instance_of(BgsPowerOfAttorney).to receive(:bgs_record).and_return(:not_found)

      expect(subject).to be true
    end
  end
end
