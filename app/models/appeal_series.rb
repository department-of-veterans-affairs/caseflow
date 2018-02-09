class AppealSeries < ActiveRecord::Base
  has_many :appeals, dependent: :nullify

  delegate :vacols_id,
           :active?,
           :type_code,
           :aod,
           :ramp_election,
           :eligible_for_ramp?,
           :form9_date,
           to: :latest_appeal

  def vacols_ids
    appeals.map(&:vacols_id)
  end

  def latest_appeal
    @latest_appeal ||= fetch_latest_appeal
  end

  def api_sort_key
    earliest_nod = appeals.map(&:nod_date).min
    earliest_nod ? earliest_nod.in_time_zone.to_f : Float::INFINITY
  end

  def location
    %w[Advance Remand].include?(latest_appeal.status) ? :aoj : :bva
  end

  def program
    programs = appeals.flat_map { |appeal| appeal.issues.map(&:program) }.uniq

    (programs.length > 1) ? :multiple : programs.first
  end

  def aoj
    appeals.lazy.flat_map(&:issues).map(&:aoj).find { |aoj| !aoj.nil? } || :other
  end

  def status
    @status ||= fetch_status
  end

  def status_hash
    { type: status, details: details_for_status }
  end

  def docket
    @docket ||= fetch_docket
  end

  def docket_hash
    docket.try(:to_hash)
  end

  def at_front
    docket.try(:at_front)
  end

  # Appeals from the same series contain many of the same events. We unique them,
  # using the property of AppealEvent that any two events with the same type and
  # date are considered equal.
  def events
    appeals.flat_map(&:events).uniq.sort_by(&:date)
  end

  def alerts
    @alerts ||= AppealSeriesAlerts.new(appeal_series: self).all
  end

  def issues
    @issues ||= AppealSeriesIssues.new(appeal_series: self).all
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

  def fetch_docket
    return unless %w[original post_remand].include?(type_code) && form9_date && !aod
    DocketSnapshot.latest.docket_tracer_for_form9_date(form9_date)
  end

  # rubocop:disable CyclomaticComplexity
  def fetch_status
    case latest_appeal.status
    when "Advance"
      disambiguate_status_advance
    when "Active"
      disambiguate_status_active
    when "Complete"
      disambiguate_status_complete
    when "Remand"
      disambiguate_status_remand
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

    if latest_appeal.form9_date
      return :pending_certification_ssoc if !latest_appeal.ssoc_dates.empty?
      return :pending_certification
    end

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
      :bva_development
    when "14", "16", "18", "24"
      latest_appeal.case_assignment_exists ? :bva_development : :on_docket
    else
      latest_appeal.case_assignment_exists ? :decision_in_progress : :on_docket
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

  def disambiguate_status_remand
    post_decision_ssocs = latest_appeal.ssoc_dates.select { |ssoc| ssoc > latest_appeal.decision_date }
    return :remand_ssoc if !post_decision_ssocs.empty?
    :remand
  end

  def details_for_status
    case status
    when :decision_in_progress
      { test: "Hello World" }
    else
      {}
    end
  end
  # rubocop:enable CyclomaticComplexity
end
