# frozen_string_literal: true

class ETL::VhaSupplementalClaimSyncer < ETL::VhaDecisionReviewSyncer
  def origin_class
    ::SupplementalClaim
  end
end
