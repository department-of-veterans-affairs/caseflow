# frozen_string_literal: true

class BulkFixStuckJob < ApplicationJob
  queue_with_priority :low_priority
  application_attr :intake
  def perform
    RequestStore[:current_user] = User.system_user

    Warroom::StuckJobsFix.new("DecisionDocument", "Claim not established.").claim_not_established
    Warroom::StuckJobsFix.new("DecisionDocument", "ClaimDateDt").claim_date_dt
    Warroom::StuckJobsFix.new("HigherLevelReview", "DTA SC Creation Failed").dta_sc_creation_failed

  rescue StandardError => error
    log_error(error)
  end
end
