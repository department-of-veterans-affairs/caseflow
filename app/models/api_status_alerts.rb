class ApiStatusAlerts
  include ActiveModel::Model

  attr_accessor :decision_review

  def all
    case decision_review
    when Appeal
      appeal_alerts
    else
      claim_review_alerts
    end
  end

  def claim_review_alerts
    [
      post_decision
    ].compact
  end

  def appeal_alerts
    [
      post_decision,
      post_remand_decision,
      post_effectuation
    ].compact
  end

  def post_decision
    return unless decision_review.api_alerts_have_decision?
    return unless Time.zone.today < decision_review.due_date_to_appeal_decision
    return if decision_review.is_a?(Appeal) && Time.zone.today > decision_review.cavc_due_date

    {
      type: "ama_post_decision",
      details:
      {
        decisionDate: decision_review.decision_date_for_api_alert,
        availableOptions: decision_review.available_review_options,
        dueDate: decision_review.due_date_to_appeal_decision,
        cavcDueDate: decision_review.is_a?(Appeal) ? decision_review.decision_date_for_api_alert + 120.days : nil
      }
    }
  end

  def post_remand_decision
    return unless decision_review.dta_decision_event_date
    return unless Time.zone.today < decision_review.dta_decision_event_date + 365.days

    {
      type: "ama_post_decision",
      details:
      {
        decisionDate: decision_review.dta_decision_event_date,
        availableOptions: decision_review.available_review_options,
        dueDate: decision_review.dta_decision_event_date + 365.days,
        cavcDueDate: decision_review.dta_decision_event_date + 120.days
      }
    }
  end

  def post_effectuation
    # only the effectuations tracked in VBMS
    return unless decision_review.decision_effectuation_event_date

    {
      type: "ama_post_decision",
      details:
      {
        decisionDate: decision_review.decision_effectuation_event_date,
        availableOptions: decision_review.available_review_options,
        dueDate: decision_review.decision_effectuation_event_date + 365.days,
        cavcDueDate: decision_review.decision_effectuation_event_date + 120.days
      }
    }
  end
end
