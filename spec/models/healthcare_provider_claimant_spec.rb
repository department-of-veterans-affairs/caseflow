# frozen_string_literal: true

describe HealthcareProviderClaimant do
  let(:appeal_with_healthcare_provider_claimant) do
    create(
      :appeal,
      has_healthcare_provider_claimant: true,
      veteran_is_not_claimant: true
    )
  end

  subject { appeal_with_healthcare_provider_claimant.claimant }

  context "#unrecognized_claimant?" do
    it "HealthcareProvider is considered an unrecognized claimant" do
      expect(subject.unrecognized_claimant?).to eq true
    end
  end
end
