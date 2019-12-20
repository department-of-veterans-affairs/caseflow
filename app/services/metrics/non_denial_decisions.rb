# frozen_string_literal: true

# Metric ID: 1709076052
# Metric definition: (Number EPs with date<=7 days after outcoding date/number non-denial decisions)

class Metrics::HearingsShowRate < Metrics::Base
  def call
    if Time.zone.now.to_date - start_date < 7.days
      fail Metrics::DateRange::DateRangeError, "Start date must be 7 days or more ago"
    end

    end_products_created_within_7_days_of_outcoding / non_denial_decisions.count
  end

  def name
    "Percent of non-denial decisions with an EP created within 7 days"
  end

  def id
    "1709076052"
  end

  private

  def offset_end_date
    # report end date should never be within 7 days of current day
    return Time.zone.now.to_date - 7.days if (Time.zone.now.to_date - end_date) < 7.days

    end_date
  end

  def appeals
    @appeals ||= BvaDispatchTask.where("closed_at >= ? AND closed_at <= ?", start_date, offset_end_date)
      .where(status: Constants.TASK_STATUSES.completed)
      .includes(:appeal)
      .map(&:appeal)
  end

  def non_denial_decisions
    @non_denial_decisions ||= DecisionIssue.where.not(disposition: "Denied")
      .where(decision_review: appeals)
  end

  def non_denial_decion_documents
    DecisionDocument.where(
      appeal_id: non_denial_decisions.pluck(:decision_review_id),
      appeal_type: "Appeal"
    )
  end

  def non_denial_end_products
    EndProductEstablishment.includes(source: [appeal: [:tasks]]).where(source: non_denial_decision_documents)
  end

  def end_products_created_within_7_days_of_outcoding
    non_denial_end_products.select do |end_product|
      (
        end_product.source.appeal.tasks.find { |task| task.type == "BvaDispatchTask" }.closed_at
        - end_product.created_at
      ) <= 7.days
    end
  end
end
