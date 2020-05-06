# frozen_string_literal: true

class ETL::VhaDecisionReviewSyncer < ETL::Syncer
  def target_class
    ETL::VhaDecisionReview
  end

  def filter?(original)
    # Opinion: move this to respective subclasses
    original.benefit_type == "vha" if [HigherLevelReview, SupplementalClaim].include?(original.class)
  end
end
