# frozen_string_literal: true

class SupplementalClaimEvents
  def initialize(appeal:)
    @appeal = appeal
  end

  def all
    [
      sc_request_event,
      sc_decision_event,
      sc_other_close_event
    ].flatten.uniq.select(&:valid?)
  end

  private

  attr_reader :appeal

  def sc_request_event
    AppealEvent.new(type: :sc_request, date: appeal.try(:receipt_date))
  end

  def sc_decision_event
    AppealEvent.new(type: :sc_decision, date: appeal.decision_event_date)
  end

  def sc_other_close_event
    AppealEvent.new(type: :sc_other_close, date: appeal.other_close_event_date)
  end
end
