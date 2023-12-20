# frozen_string_literal: true

class ETL::VhaClaimReviewSyncer < ETL::VhaDecisionReviewSyncer
  protected

  def instances_needing_update
    super.processed.where(benefit_type: "vha")
  end
end
