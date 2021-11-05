# frozen_string_literal: true

class DirectReviewDocket < Docket
  def docket_type
    Constants.AMA_DOCKETS.direct_review
  end

  def due_count
    appeal_ids = appeals(priority: false, ready: true)
      .where("target_decision_date <= ?", Constants.DISTRIBUTION.days_before_goal_due_for_distribution.days.from_now)
    Appeal.where(id: appeal_ids).count
  end

  def time_until_due_of_oldest_appeal
    oldest_target = nonpriority_nonihp_ready_appeals.limit(1).first&.target_decision_date
    return time_until_due_of_new_appeal unless oldest_target

    time_until_due = Integer(oldest_target - Time.zone.today.to_date) -
                     Constants.DISTRIBUTION.days_before_goal_due_for_distribution
    time_until_due.clamp(0, time_until_due_of_new_appeal)
  end

  def time_until_due_of_new_appeal
    Constants.DISTRIBUTION.direct_docket_time_goal - Constants.DISTRIBUTION.days_before_goal_due_for_distribution
  end

  def nonpriority_receipts_per_year
    number_of_nonpriority_appeals_received_in_the_past_year
  end

  private

  def number_of_nonpriority_appeals_received_in_the_past_year
    all_nonpriority.where("receipt_date > ?", 1.year.ago).ids.size
  end

  def today
    @today ||= Time.zone.today
  end

  def all_nonpriority
    docket_appeals.nonpriority
  end

  def nonpriority_nonihp_ready_appeals
    docket_appeals
      .ready_for_distribution
      .nonpriority
      .non_ihp
      .order("receipt_date")
  end
end
