class DirectReviewDocket < Docket
  DAYS_TO_DECISION_GOAL = 365
  DAYS_BEFORE_GOAL_DUE_FOR_DISTRIBUTION = 60

  def docket_type
    "direct_review"
  end

  def due_count
    appeal_ids = appeals(priority: false, ready: true)
      .where("target_decision_date <= ?", DAYS_BEFORE_GOAL_DUE_FOR_DISTRIBUTION.days.from_now)
    Appeal.where(id: appeal_ids).count
  end

  def time_until_due_of_oldest_appeal
    oldest_target = nonpriority_nonihp_ready_appeals.limit(1).first.target_decision_date
    time_until_due = Integer(oldest_target - Time.zone.today.to_date) - DAYS_BEFORE_GOAL_DUE_FOR_DISTRIBUTION
    time_until_due.clamp(0, time_until_due_of_new_appeal)
  end

  def time_until_due_of_new_appeal
    DAYS_TO_DECISION_GOAL - DAYS_BEFORE_GOAL_DUE_FOR_DISTRIBUTION
  end

  def nonpriority_receipts_per_year
    today = Time.zone.today

    if today < Date.new(2019, 4, 1)
      # Hardcode this figure as a baseline since we won't have enough data to judge.
      return 38_500
    elsif today < Date.new(2020, 2, 29)
      # If it's been fewer than 365 days since March 1st, return a weighted number of appeals.
      march_first = Date.new(2019, 3, 1)
      days_since_march_first = Integer(today - march_first)
      appeals_since_march_first =
        all_nonpriority.where("receipt_date > ?", march_first).count.length
      # appeals_since_march_first / adjusted_appeals = days_since_march_first / 365
      ((appeals_since_march_first * 365) / days_since_march_first).round
    else
      all_nonpriority.where("receipt_date > ?", 1.year.ago).count.length
    end
  end

  private

  def all_nonpriority
    Appeal.all_nonpriority.where(docket_type: docket_type)
  end

  def nonpriority_nonihp_ready_appeals
    docket_appeals
      .merge(Appeal.ready_for_distribution)
      .merge(Appeal.all_nonpriority)
      .merge(Appeal.non_ihp)
      .order("receipt_date")
  end
end
