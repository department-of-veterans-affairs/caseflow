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
      post_effectuation,
      evidentiary_period
    ].flatten.compact.uniq
  end

  def post_decision
    return unless decision_review.api_alerts_show_decision_alert?
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
    return unless decision_review.remand_decision_event_date
    return unless Time.zone.today < decision_review.remand_decision_event_date + 365.days

    decision_review.remand_supplemental_claims.map do |remand_sc|
      {
        type: "ama_post_decision",
        details:
        {
          decisionDate: remand_sc.decision_event_date,
          availableOptions: remand_sc.available_review_options,
          dueDate: remand_sc.decision_event_date + 365.days,
          cavcDueDate: remand_sc.decision_event_date + 120.days
        }
      }
    end
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

  def evidentiary_period
    return unless decision_review.evidence_submission_hold_pending?

    task = decision_review.tasks.active.find_by(type: EvidenceSubmissionWindowTask.name)

    {
      type: "evidentiary_period",
      details: {
        due_date: task.timer_ends_at.to_date
      }
    }
  end
end
