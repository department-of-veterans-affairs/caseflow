# frozen_string_literal: true

describe HealthcareProviderClaimant do
  let(:claimant) { create(:claimant, type: "HealthcareProviderClaimant") }

  describe "#unrecognized_claimant?" do
    subject { claimant.unrecognized_claimant? }

    it "HealthcareProviderClaimant is considered an unrecognized claimant" do
      is_expected.to eq true
    end
  end
end
