# frozen_string_literal: true

# Metric ID: 1709076052
# Metric definition: (Number EPs with date<=7 days after outcoding date/number non-denial decisions)

class Metrics::NonDenialDecisions < Metrics::Base
  def initialize(date_range, appeal_type: "Appeal", within: 7)
    super(date_range)

    @appeal_type = appeal_type
    @within = within.to_i

    if start_or_end_date_within_n_days
      fail Metrics::DateRange::DateRangeError, "Start and end dates must be #{within} days or more ago"
    end
  end

  def call
    end_products_created_within_n_days_of_outcoding.count / appeals_with_non_denial_decisions.count.to_f
  end

  def name
    "Percent of non-denial decisions with an EP created within #{within} days"
  end

  def id
    "1709076052"
  end

  private

  attr_reader :appeal_type, :within

  def start_or_end_date_within_n_days
    n_days_ago = (Time.zone.now - within.days).to_date
    end_date > n_days_ago || start_date > n_days_ago
  end

  def completed_dispatch_tasks
    completed = BvaDispatchTask.completed
    appeal_type ? completed.where(appeal_type: appeal_type) : completed
  end

  def appeals_in_range
    completed_dispatch_tasks.where("closed_at >= ? AND closed_at <= ?", start_date, end_date)
      .includes(:appeal)
      .map(&:appeal)
  end

  def appeals_with_non_denial_decisions
    @appeals_with_non_denial_decisions ||= DecisionIssue.not_denied
      .where(decision_review: appeals_in_range)
      .includes(:decision_review)
      .map(&:decision_review)
  end

  def non_denial_decision_documents
    DecisionDocument.where(appeal: appeals_with_non_denial_decisions)
  end

  def non_denial_end_products
    EndProductEstablishment.includes(source: [appeal: [:tasks]])
      .where(source: non_denial_decision_documents)
      .where.not(established_at: nil)
  end

  def end_products_created_within_n_days_of_outcoding
    non_denial_end_products.select do |epe|
      bva_dispatch_task = bva_dispatch_task_for(epe)
      fail "No BvaDispatchTask found for EP #{epe.id}" unless bva_dispatch_task

      epe_date = epe.created_at || epe.established_at
      bva_dispatch_task.closed_at - epe_date <= within.days
    end
  end

  def bva_dispatch_task_for(end_product_establishment)
    end_product_establishment.source.appeal.tasks.completed.find_by(type: "BvaDispatchTask")
  end
end
