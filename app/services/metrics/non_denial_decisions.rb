# frozen_string_literal: true

# Metric ID: 1709076052
# Metric definition: (Number EPs with date<=7 days after outcoding date/number non-denial decisions)

class Metrics::NonDenialDecisions < Metrics::Base
  def initialize(date_range)
    super(date_range)

    if start_or_end_date_within_7_days
      fail Metrics::DateRange::DateRangeError, "Start and end dates must be 7 days or more ago"
    end
  end

  def call
    end_products_created_within_7_days_of_outcoding.count / appeals_with_non_denial_decisions.count.to_f
  end

  def name
    "Percent of non-denial decisions with an EP created within 7 days"
  end

  def id
    "1709076052"
  end

  private

  def start_or_end_date_within_7_days
    seven_days_ago = (Time.zone.now - 7.days).to_date
    end_date > seven_days_ago || start_date > seven_days_ago
  end

  def appeals_in_range
    BvaDispatchTask.where("closed_at >= ? AND closed_at <= ?", start_date, end_date)
      .where(status: Constants.TASK_STATUSES.completed)
      .includes(:appeal)
      .map(&:appeal)
  end

  def appeals_with_non_denial_decisions
    @appeals_with_non_denial_decisions ||= DecisionIssue.where
      .not(disposition: "Denied")
      .where(decision_review: appeals_in_range)
      .includes(:decision_review)
      .map(&:decision_review)
  end

  def non_denial_decision_documents
    DecisionDocument.where(appeal: appeals_with_non_denial_decisions)
  end

  def non_denial_end_products
    EndProductEstablishment.includes(source: [appeal: [:tasks]]).where(source: non_denial_decision_documents)
  end

  def end_products_created_within_7_days_of_outcoding
    non_denial_end_products.select do |end_product|
      bva_dispatch_task = end_product.source.appeal.tasks.completed.find do |task|
        task.type == "BvaDispatchTask"
      end
      fail "No BvaDispatchTask found for EP #{end_product.id}" unless bva_dispatch_task
      ep_date = end_product.created_at || end_product.established_at
      bva_dispatch_task.closed_at - ep_date <= 7.days
    end
  end
end
