class AppealEvents
  include ActiveModel::Model

  attr_accessor :appeal

  def all
    [
      nod_event,
      soc_event,
      form9_event,
      ssoc_events,
      certification_event,
      activation_event,
      hearing_events,
      decision_event
    ].flatten.select(&:valid?)
  end

  private

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

  def certification_event
    AppealEvent.new(type: :certified, date: appeal.certification_date)
  end

  def activation_event
    AppealEvent.new(type: :activated, date: appeal.case_review_date)
  end

  def hearing_events
    appeal.hearings.select(&:closed?).map { |hearing| AppealEvent.new(hearing: hearing) }
  end
end
