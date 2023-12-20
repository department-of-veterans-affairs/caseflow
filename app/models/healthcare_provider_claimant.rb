# frozen_string_literal: true

# HealthcareProviderClaimant is used whenever a HCP (Healthcare Provider)
# is not listed in CorpDB, allowing a claim to be processed through Intake
# despite its absence.

class HealthcareProviderClaimant < OtherClaimant; end
