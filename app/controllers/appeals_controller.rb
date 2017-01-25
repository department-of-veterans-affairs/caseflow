class AppealsController < ApplicationController
  before_action :verify_manage_claim_establishment

  def appeals_missing_decisions
    @appeals_missing_decisions ||= Appeal.find_appeals_missing_decisions #.order(days_in_queue: :desc)
  end
  helper_method :appeals_missing_decisions
end
