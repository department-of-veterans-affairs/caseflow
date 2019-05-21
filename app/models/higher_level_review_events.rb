# frozen_string_literal: true

class HigherLevelReviewEvents
  def initialize(appeal:)
    @appeal = appeal
  end

  def all
    [
      hlr_request_event,
      hlr_decision_event,
      hlr_dta_error_event,
      dta_decision_event,
      hlr_other_close_event
    ].flatten.uniq.select(&:valid?)
  end

  private

  attr_reader :appeal

  def hlr_request_event
    AppealEvent.new(type: :hlr_request, date: appeal.try(:receipt_date))
  end

  def hlr_decision_event
    AppealEvent.new(type: :hlr_decision, date: appeal.decision_event_date)
  end

  def hlr_dta_error_event
    AppealEvent.new(type: :hlr_dta_error, date: appeal.dta_error_event_date)
  end

  def hlr_other_close_event
    AppealEvent.new(type: :hlr_other_close, date: appeal.other_close_event_date)
  end
end
