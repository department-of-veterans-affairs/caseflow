# frozen_string_literal: true

# Metric ID: 1812216039
# Metric definition: (Number EPs with date<=7 days after outcoding date/number non-denial decisions)

class Metrics::HearingsShowRate < Metrics::Base
  def call
    end_products_created_within_7_days_of_outcoding / non_denial_decisions.count
  end

  def name
    "Percent of non-denial decisions with an EP created within 7 days"
  end

  def id
    "1709076052"
  end

  private

  def non_denial_decisions
    @non_denial_decisions ||= DecisionIssue
      .where("caseflow_decision_date >= ? AND caseflow_decision_date <= ?", start_date, end_date)
      .where.not(disposition: "Denied")
      .where(decision_review_type: "Appeal")
  end

  def non_denial_decisions_end_products
    decision_documents = DecisionDocument.where(
      appeal: Appeal.where(id: non_denial_decisions.pluck(:decision_review_id))
    )
    EndProductEstablishment.includes(source: [appeal: [:tasks]]).where(source: decision_documents)
  end

  def end_products_created_within_7_days_of_outcoding
    non_denial_decisions_end_products.select do |end_product|
      (
        end_product.source.appeal.tasks.find { |task| task.type == "BvaDispatchTask" }.closed_at
        - end_product.created_at
      ) <= 7.days
    end
  end
end
