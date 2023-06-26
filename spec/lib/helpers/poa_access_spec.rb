# frozen_string_literal: true

require "helpers/poa_access"

describe "WarRoom::PoaAccess" do
  let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

  context "when run against a legacy appeal" do

    subject { WarRoom::PoaAccess.new(appeal.vacols_id, "fake-pid").run }

    it "interrupts when poa is present" do
      expect { subject }.to raise_error do |error|
        expect(error).to be_a(Interrupt)
      end
    end

    subject { WarRoom::PoaAccess.new(appeal.vacols_id, "").run }

    it "creates a person record for spouse" do
      allow_any_instance_of(BgsPowerOfAttorney).to receive(:bgs_record).and_return(:not_found)

      expect(subject).to be true
    end
  end
end
