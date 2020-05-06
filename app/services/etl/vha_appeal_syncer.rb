# frozen_string_literal: true

class ETL::VhaAppealSyncer < ETL::VhaDecisionReviewSyncer
  def origin_class
    ::Appeal
  end

  def filter?(original)
    original.request_issues.map(&:benefit_type).include?("vha")
  end

  protected

  # TODO: def instances_needing_update
    # super.where(benefit_type: "vha")
  # end
end
