class AppealEvents
  include ActiveModel::Model

  attr_accessor :appeal

  def all
    scope_to_appeal(all_unscoped)
  end

  private

  def all_unscoped
    [
      nod_event,
      soc_event,
      form9_event,
      ssoc_events,
      certification_event,
      activation_event,
      hearing_events,
      decision_event,
      cavc_decision_events
    ].flatten.select(&:valid?)
  end

  # If there is a prior_decision_date for this appeal, we should scope
  # events to only those made after the prior_decision_date, because
  # any events that happened before the prior_decision_date are associated
  # with the remanded appeal, not this appeal.
  def scope_to_appeal(events)
    return events unless appeal.prior_decision_date

    events.reject { |event| event.date < appeal.prior_decision_date }
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
    appeal.ssoc_dates.map do |ssoc_date|
      # If the SSOC was released after the appeal was certified,
      # mark it as a post-remand ssoc so consumers of the API
      # can easily tell which SSOCs happened at which step of the process.
      if appeal.certification_date && ssoc_date > appeal.certification_date
        AppealEvent.new(type: :remand_ssoc, date: ssoc_date)
      else
        AppealEvent.new(type: :ssoc, date: ssoc_date)
      end
    end
  end

  def decision_event
    AppealEvent.new(disposition: appeal.disposition_remand_priority, date: appeal.decision_date)
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

  def cavc_decision_events
    appeal.cavc_decisions.map(&:decision_date).uniq.map do |cavc_decision_date|
      AppealEvent.new(type: :cavc_decision, date: cavc_decision_date)
    end
  end
end
