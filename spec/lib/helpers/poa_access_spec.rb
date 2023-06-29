# frozen_string_literal: true

require "helpers/poa_access"

describe "WarRoom::PoaAccess" do
  before do
    allow(FeatureToggle).to receive(:enabled?).
      with(:poa_auto_refresh, user: RequestStore.store[:current_user]) { true } 
  end

  let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
  let(:poa) { create(:bgs_power_of_attorney, claimant_participant_id: "2", poa_participant_id: "1") }

  context "when run against a legacy appeal" do
    subject { WarRoom::PoaAccess.new(appeal.vacols_id, "not-used").run }
    it "interrupts when poa is found" do
      expect { subject }.to raise_error do |error|
        expect(error).to be_a(Interrupt)
      end
    end

    subject { WarRoom::PoaAccess.new(appeal.vacols_id, poa.claimant_participant_id).run }
    it "creates a person record for spouse when poa :not_found" do
      # To avoid adding to the large amount of dummy data lets just coerce the record to be :not_found
      allow_any_instance_of(BgsPowerOfAttorney).to receive(:bgs_record).and_return(:not_found)

      expect(subject).to be true
    end
  end
end
