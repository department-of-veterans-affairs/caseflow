class AppealEvents
  include ActiveModel::Model

  attr_accessor :appeal
  attr_accessor :version

  def all
    case appeal
    when LegacyAppeal
      legacy_appeal_events
    when SupplementalClaim
      sc_events
    when HigherLevelReview
      hlr_events
    end
  end

  def legacy_appeal_events
    [
      claim_event,
      nod_event,
      soc_event,
      form9_event,
      ssoc_events,
      certification_event,
      remand_return_event,
      hearing_events,
      hearing_transcript_events,
      decision_event,
      issue_event,
      ramp_notice_event,
      cavc_decision_events
    ].flatten.uniq.select(&:valid?)
  end

  def sc_events
    [
      sc_request_event,
      sc_decision_event,
      sc_other_close_event
    ].flatten.uniq.select(&:valid?)
  end

  def hlr_events
    [
      hlr_request_event,
      hlr_decision_event,
      hlr_dta_error_event,
      dta_decision_event,
      hlr_other_close_event
    ].flatten.uniq.select(&:valid?)
  end

  private

  def claim_event
    AppealEvent.new(type: :claim_decision, date: appeal.notification_date)
  end

  def nod_event
    AppealEvent.new(type: :nod, date: appeal.nod_date)
  end

  def soc_event
    AppealEvent.new(type: :soc, date: appeal.soc_date)
  end

  def form9_event
    AppealEvent.new(type: :form9, date: appeal.form9_date)
  end

  def ssoc_events
    appeal.ssoc_dates.map { |ssoc_date| AppealEvent.new(type: :ssoc, date: ssoc_date) }
  end

  def decision_event
    AppealEvent.new(disposition: appeal.disposition, date: appeal.decision_date)
  end

  def issue_event
    appeal.issues.map do |issue|
      AppealEvent.new(issue_disposition: issue.disposition, date: issue.close_date)
    end
  end

  def certification_event
    AppealEvent.new(type: :certified, date: appeal.certification_date)
  end

  def activation_event
    AppealEvent.new(type: :activated, date: appeal.case_review_date)
  end

  def remand_return_event
    AppealEvent.new(type: :remand_return, date: appeal.remand_return_date)
  end

  def hearing_events
    appeal.hearings.select(&:closed?).map { |hearing| AppealEvent.new(hearing: hearing) }
  end

  def hearing_transcript_events
    appeal.hearings.select(&:held?).map do |hearing|
      AppealEvent.new(type: :transcript, date: hearing.transcript_sent_date)
    end
  end

  def cavc_decision_events
    appeal.cavc_decisions.map(&:decision_date).uniq.map do |cavc_decision_date|
      AppealEvent.new(type: :cavc_decision, date: cavc_decision_date)
    end
  end

  def ramp_notice_event
    AppealEvent.new(type: :ramp_notice, date: appeal.ramp_election.try(:notice_date))
  end

  def sc_request_event
    AppealEvent.new(type: :sc_request, date: appeal.try(:receipt_date))
  end

  def sc_decision_event
    AppealEvent.new(type: :sc_decision, date: appeal.decision_event_date)
  end

  def sc_other_close_event
    AppealEvent.new(type: :sc_other_close, date: appeal.other_close_event_date)
  end

  def hlr_request_event
    AppealEvent.new(type: :hlr_request, date: appeal.try(:receipt_date))
  end

  def hlr_decision_event
    AppealEvent.new(type: :hlr_decision, date: appeal.decision_event_date)
  end

  def hlr_dta_error_event
    AppealEvent.new(type: :hlr_dta_error, date: appeal.dta_error_event_date)
  end

  def dta_decision_event
    AppealEvent.new(type: :dtaDecision, date: appeal.dta_descision_event_date)
  end

  def hlr_other_close_event
    AppealEvent.new(type: :hlr_other_close, date: appeal.other_close_event_date)
  end
end
