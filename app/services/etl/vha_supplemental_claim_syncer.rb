# frozen_string_literal: true

class ETL::VhaSupplementalClaimSyncer < ETL::VhaClaimReviewSyncer
  def origin_class
    ::SupplementalClaim
  end
end
