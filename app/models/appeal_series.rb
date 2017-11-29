class AppealSeries < ActiveRecord::Base
  has_many :appeals, dependent: :nullify

  delegate :vacols_id,
           :active?,
           :type_code,
           :aod,
           to: :latest_appeal

  def latest_appeal
    @latest_appeal ||= fetch_latest_appeal
  end

  def api_sort_date
    appeals.map(&:nod_date).min || DateTime::Infinity.new
  end

  def location
    (%w(Advance Remand).include? latest_appeal.status) ? :aoj : :bva
  end

  def status
    @status ||= fetch_status
  end

  def status_hash
    case status
    when :decision_in_progress
      details = { test: "Hello World" }
    else
      details = {}
    end

    { type: status, details: details }
  end

  def events
    appeals.flat_map(&:events).uniq
  end

  private

  def fetch_latest_appeal
    active_appeals.first || appeals_by_decision_date.first
  end

  def active_appeals
    appeals.select(&:active?)
           .sort { |x, y| y.last_location_change_date <=> x.last_location_change_date }
  end

  def appeals_by_decision_date
    appeals.sort { |x, y| y.decision_date <=> x.decision_date }
  end

  def fetch_status
    case latest_appeal.status
    when "Advance"
      disambiguate_status_advance
    when "Active"
      disambiguate_status_active
    when "Complete"
      disambiguate_status_complete
    when "Remand"
      :remand
    when "Motion"
      :motion
    when "CAVC"
      :cavc
    end
  end

  def disambiguate_status_advance
    if latest_appeal.certification_date
      return :scheduled_hearing if latest_appeal.hearing_scheduled?
      return :pending_hearing_scheduling if latest_appeal.hearing_pending?
      return :on_docket
    end

    return :pending_certification if latest_appeal.form9_date

    return :pending_form9 if latest_appeal.soc_date

    :pending_soc
  end

  def disambiguate_status_active
    return :scheduled_hearing if latest_appeal.hearing_scheduled?

    case latest_appeal.location_code
    when "49"
      :stayed
    when "55"
      :at_vso
    when "19", "20"
      :opinion_request
    when "14", "16", "18", "24"
      latest_appeal.case_assignment_exists? ? :abeyance : :on_docket
    else
      latest_appeal.case_assignment_exists? ? :decision_in_progress : :on_docket
    end
  end

  def disambiguate_status_complete
    case latest_appeal.disposition
    when "Allowed", "Denied"
      :bva_decision
    when "Advance Allowed in Field", "Benefits Granted by AOJ"
      :field_grant
    when "Withdrawn", "Advance Withdrawn by Appellant/Rep",
         "Recon Motion Withdrawn", "Withdrawn from Remand"
      :withdrawn
    when "Advance Failure to Respond", "Remand Failure to Respond"
      :ftr
    when "RAMP Opt-in"
      :ramp
    when "Dismissed, Death", "Advance Withdrawn Death of Veteran"
      :death
    when "Reconsideration by Letter"
      :reconsideration
    else
      :other_close
    end
  end
end
