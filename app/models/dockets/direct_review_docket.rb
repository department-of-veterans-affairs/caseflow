# frozen_string_literal: true

class DirectReviewDocket < Docket
  def docket_type
    Constants.AMA_DOCKETS.direct_review
  end

  def due_count
    ama_direct_review_start_distribution_prior_to_goals =
      CaseDistributionLever.ama_direct_review_start_distribution_prior_to_goals
    appeal_ids = if ama_direct_review_start_distribution_prior_to_goals > 0
                   appeals(priority: false, ready: true, not_affinity: true)
                     .where("target_decision_date <= ?",
                            ama_direct_review_start_distribution_prior_to_goals.days.from_now)
                 else
                   appeals(priority: false, ready: true,  not_affinity: true)
                 end

    Appeal.where(id: appeal_ids).count
  end

  def nonpriority_receipts_per_year
    number_of_nonpriority_appeals_received_in_the_past_year
  end

  private

  def number_of_nonpriority_appeals_received_in_the_past_year
    all_nonpriority.where("receipt_date > ?", 1.year.ago).ids.size
  end

  def all_nonpriority
    docket_appeals.nonpriority
  end
end
