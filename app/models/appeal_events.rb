# frozen_string_literal: true

class AppealEvents
  def initialize(appeal:)
    @appeal = appeal
  end

  def all
    [
      ama_nod_event,
      distributed_to_vlj_event,
      bva_decision_event,
      bva_decision_effectuation_event,
      dta_decision_event,
      other_close_event
    ].flatten.uniq.select(&:valid?)
  end

  private

  attr_reader :appeal

  # NOT USED
  def activation_event
    AppealEvent.new(type: :activated, date: appeal.case_review_date)
  end

  def ama_nod_event
    AppealEvent.new(type: :ama_nod, date: appeal.try(:receipt_date))
  end

  def distributed_to_vlj_event
    AppealEvent.new(type: :distributed_to_vlj, date: appeal.first_distributed_to_judge_date)
  end

  def bva_decision_event
    AppealEvent.new(type: :bva_decision, date: appeal.decision_event_date)
  end

  def bva_decision_effectuation_event
    AppealEvent.new(type: :bva_decision_effectuation,
                    date: appeal.decision_issues.remanded.any? ? nil : appeal.decision_effectuation_event_date)
  end

  def dta_decision_event
    AppealEvent.new(type: :dta_decision, date: appeal.remand_decision_event_date)
  end

  def other_close_event
    AppealEvent.new(type: :other_close, date: appeal.other_close_event_date)
  end
end
