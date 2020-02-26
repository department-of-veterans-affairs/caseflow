# frozen_string_literal: true

class AppealSeries < ApplicationRecord
  has_many :appeals, class_name: "LegacyAppeal", dependent: :nullify

  # Timeliness is returned as a range of integer months from 50 to 84.1%tile.
  # TODO: Replace these hardcoded values with dynamic data
  SOC_TIMELINESS           = [10, 26].freeze # 75%tile = 20
  SSOC_TIMELINESS          = [5, 13].freeze  # 75%tile = 10
  CERTIFICATION_TIMELINESS = [2, 8].freeze   # 75%tile = 5
  DECISION_TIMELINESS      = [1, 2].freeze   # 75%tile = 1
  REMAND_TIMELINESS        = [16, 29].freeze # 75%tile = 25
  REMAND_SSOC_TIMELINESS   = [3, 11].freeze  # 75%tile = 9
  RETURN_TIMELINESS        = [1, 2].freeze   # 75%tile = 2

  delegate :vacols_id,
           :active?,
           :type_code,
           :representative_name,
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
    earliest_nod = appeals.map(&:nod_date).compact.min
    earliest_nod ? earliest_nod.in_time_zone.to_f : Float::INFINITY
  end

  def location
    %w[Advance Remand].include?(latest_appeal.status) ? :aoj : :bva
  end

  def program
    programs = appeals.flat_map { |appeal| appeal.issues.map(&:program) }.reject(&:nil?).uniq

    (programs.length > 1) ? :multiple : programs.first
  end

  def aoj
    appeals.lazy.flat_map(&:issues).map(&:aoj).find { |aoj| !aoj.nil? } || :other
  end

  def status
    @status ||= fetch_status
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

  def description
    ordered_issues = latest_appeal.issues
      .select(&:codes?)
      .sort_by(&:vacols_sequence_id)
      .partition(&:diagnostic_code).flatten

    return "VA needs to record issues" if ordered_issues.empty?

    marquee_issue_description = ordered_issues.first.friendly_description_without_new_material

    return marquee_issue_description if issues.length == 1

    comma = (marquee_issue_description.count(",") > 0) ? "," : ""
    issue_count = issues.count - 1

    "#{marquee_issue_description}#{comma} and #{issue_count} #{'other'.pluralize(issue_count)}"
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
      disambiguate_status_remand
    when "Motion"
      :motion
    when "CAVC"
      :cavc
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def fetch_details_for_status
    case status
    when :scheduled_hearing
      hearing = latest_appeal.scheduled_hearings.min_by(&:scheduled_for)

      {
        date: hearing.scheduled_for.to_date,
        type: hearing.readable_request_type.downcase,
        location: hearing.request_type_location
      }
    when :pending_hearing_scheduling
      { type: latest_appeal.sanitized_hearing_request_type }
    when :pending_form9, :pending_certification, :pending_certification_ssoc
      {
        last_soc_date: last_soc_date,
        certification_timeliness: CERTIFICATION_TIMELINESS.dup,
        ssoc_timeliness: SSOC_TIMELINESS.dup
      }
    when :pending_soc
      { soc_timeliness: SOC_TIMELINESS.dup }
    when :at_vso
      { vso_name: representative_name }
    when :decision_in_progress
      { decisionTimeliness: DECISION_TIMELINESS.dup }
    when :remand
      {
        issues: issues_for_last_decision,
        remand_timeliness: REMAND_TIMELINESS.dup
      }
    when :remand_ssoc
      {
        last_soc_date: last_soc_date,
        return_timeliness: RETURN_TIMELINESS.dup,
        remand_ssoc_timeliness: REMAND_SSOC_TIMELINESS.dup
      }
    when :bva_decision
      { issues: issues_for_last_decision }
    else
      {}
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  def fetch_latest_appeal
    latest_active_appeal_by_last_location_change_date || latest_appeal_by_decision_date
  end

  def latest_active_appeal_by_last_location_change_date
    appeals.select(&:active?).max_by(&:last_location_change_date)
  end

  def latest_appeal_by_decision_date
    # explicit cast to_i to allow for nil comparison with Time object
    appeals.max_by { |appeal| appeal.decision_date.to_i }
  end

  def fetch_docket
    return unless active? && %w[original post_remand].include?(type_code) && form9_date && !aod

    DocketSnapshot.latest.docket_tracer_for_form9_date(form9_date)
  end

  def last_soc_date
    events.reverse.detect { |event| [:soc, :ssoc].include? event.type }.date.to_date
  end

  def issues_for_last_decision
    latest_appeal.issues.select { |issue| [:allowed, :remanded, :denied].include? issue.disposition }.map do |issue|
      {
        description: issue.friendly_description,
        disposition: issue.disposition
      }
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
    when "AMA SOC/SSOC Opt-in"
      :statutory_opt_in
    when "Dismissed, Death", "Advance Withdrawn Death of Veteran"
      :death
    when "Reconsideration by Letter"
      :reconsideration
    when "Merged Appeal"
      :merged
    else
      :other_close
    end
  end

  def disambiguate_status_remand
    post_decision_ssocs = latest_appeal.ssoc_dates.select { |ssoc| ssoc > latest_appeal.decision_date }
    return :remand_ssoc if !post_decision_ssocs.empty?

    :remand
  end
end
