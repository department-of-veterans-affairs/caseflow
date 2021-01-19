# frozen_string_literal: true

class DirectReviewDocket < Docket
  DAYS_TO_DECISION_GOAL = 365
  DAYS_BEFORE_GOAL_DUE_FOR_DISTRIBUTION = 65

  def docket_type
    Constants.AMA_DOCKETS.direct_review
  end

  def due_count
    appeal_ids = appeals(priority: false, ready: true)
      .where("target_decision_date <= ?", DAYS_BEFORE_GOAL_DUE_FOR_DISTRIBUTION.days.from_now)
    Appeal.where(id: appeal_ids).count
  end

  def time_until_due_of_oldest_appeal
    oldest_target = nonpriority_nonihp_ready_appeals.limit(1).first&.target_decision_date
    return time_until_due_of_new_appeal unless oldest_target

    time_until_due = Integer(oldest_target - Time.zone.today.to_date) - DAYS_BEFORE_GOAL_DUE_FOR_DISTRIBUTION
    time_until_due.clamp(0, time_until_due_of_new_appeal)
  end

  def time_until_due_of_new_appeal
    DAYS_TO_DECISION_GOAL - DAYS_BEFORE_GOAL_DUE_FOR_DISTRIBUTION
  end

  def nonpriority_receipts_per_year
    # This conditional should be removed on March 1, 2020
    if current_date_earlier_than_feb_29_2020?
      prorated_nonpriority_appeals_per_year_based_on_days_since_march_first_2019
    else
      number_of_nonpriority_appeals_received_in_the_past_year
    end
  end

  private

  def current_date_earlier_than_feb_29_2020?
    today < Date.new(2020, 2, 29)
  end

  def prorated_nonpriority_appeals_per_year_based_on_days_since_march_first_2019
    ((nonpriority_appeals_since_march_first_2019 * 365) / days_since_march_first_2019).round
  end

  def number_of_nonpriority_appeals_received_in_the_past_year
    all_nonpriority.where("receipt_date > ?", 1.year.ago).ids.size
  end

  def today
    @today ||= Time.zone.today
  end

  def nonpriority_appeals_since_march_first_2019
    all_nonpriority.where("receipt_date > ?", march_first).ids.size
  end

  def days_since_march_first_2019
    Integer(today - march_first)
  end

  def march_first
    @march_first ||= Date.new(2019, 3, 1)
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
