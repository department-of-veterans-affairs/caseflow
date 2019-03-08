# frozen_string_literal: true

class SupplementalClaimsController < ClaimReviewController
  SOURCE_TYPE = "SupplementalClaim"

  private

  def source_type
    SOURCE_TYPE
  end

  alias supplemental_claim claim_review
  helper_method :supplemental_claim, :url_claim_id
end
