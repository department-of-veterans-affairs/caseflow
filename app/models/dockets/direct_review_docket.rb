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

  # TODO: this appears to be dead code leftover from https://github.com/department-of-veterans-affairs/caseflow/pull/16924
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
