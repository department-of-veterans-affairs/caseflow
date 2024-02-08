# frozen_string_literal: true

class DirectReviewDocket < Docket
  def docket_type
    Constants.AMA_DOCKETS.direct_review
  end

  def due_count
    days_before_goal_due_for_distribution = CaseDistributionLever.days_before_goal_due_for_distribution
    appeal_ids = if days_before_goal_due_for_distribution > 0
                   appeals(priority: false, ready: true)
                     .where("target_decision_date <= ?", days_before_goal_due_for_distribution.days.from_now)
                 else
                   appeals(priority: false, ready: true)
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
