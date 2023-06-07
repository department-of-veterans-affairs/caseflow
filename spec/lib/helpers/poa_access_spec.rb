# frozen_string_literal: true

require "helpers/poa_access"

describe "WarRoom::PoaAccess" do
  let(:legacy_appeal) { create(:legacy_appeal) }
  let(:bgs_poa) { create(:bgs_power_of_attorney) }
  let(:error_type) { Interrupt }

  context "when run against a legacy appeal" do
    subject { WarRoom::PoaAccess.new(legacy_appeal.id, bgs_poa.participant_id).run }
    it "aborts when poa is present" do
      expect(subject).to raise_error do |error|
        expect(error).to be_a(error_type)
      end
    end
  end
end
