# frozen_string_literal: true

class ETL::VhaAppealSyncer < ETL::VhaDecisionReviewSyncer
  def origin_class
    ::Appeal
  end

  def target_class
    ETL::DecisionReview::Appeal
  end

  protected

  def instances_needing_update
    return where_vha_request_issues(origin_class.established) unless incremental?

    where_vha_request_issues(AppealsUpdatedSinceQuery.new(since_date: since).call)
  end

  private

  def where_vha_request_issues(query)
    query.where(id: vha_appeal_ids)
  end

  def vha_appeal_ids
    RequestIssue.select(:decision_review_id).where(benefit_type: "vha", decision_review_type: :Appeal)
  end
end
