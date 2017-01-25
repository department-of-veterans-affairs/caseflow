class AppealsController < ApplicationController
  before_action :verify_manage_claim_establishment

  def appeals_missing_decisions
    @appeals_missing_decisions ||= Appeal.find_appeals_missing_decisions
  end
  helper_method :appeals_missing_decisions

  def logo_name
    "Dispatch"
  end

  def logo_path
    establish_claims_path
  end
end
