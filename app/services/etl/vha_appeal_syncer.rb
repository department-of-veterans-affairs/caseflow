# frozen_string_literal: true

class ETL::VhaAppealSyncer < ETL::VhaDecisionReviewSyncer
  def origin_class
    ::Appeal
  end

  def target_class
    ETL::VhaAppeal
  end

  def filter?(original)
    # TODO: incorporate this into AppealsUpdatedSinceQuery
    original.request_issues.map(&:benefit_type).include?("vha")
  end

  protected

  def instances_needing_update
    return origin_class.established unless incremental?

    AppealsUpdatedSinceQuery.new(since_date: since).call
  end

end
