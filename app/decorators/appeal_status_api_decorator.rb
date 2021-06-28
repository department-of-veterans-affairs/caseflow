# frozen_string_literal: true

# Extends the Appeal model with methods for the Appeals Status API

class AppealStatusApiDecorator < ApplicationDecorator
  def appeal_status_id
    "A#{id}"
  end

  def linked_review_ids
    Array.wrap(appeal_status_id)
  end

  def active_status?
    # For the appeal status api, and Appeal is considered open
    # as long as there are active remand claim or effectuation
    # tracked in VBMS.
    active? || active_effectuation_ep? || active_remanded_claims?
  end

  def active_effectuation_ep?
    decision_document&.end_product_establishments&.any? { |ep| ep.status_active?(sync: false) }
  end

  def location
    if active_effectuation_ep? || active_remanded_claims?
      "aoj"
    else
      "bva"
    end
  end

  def fetch_status
    if active?
      fetch_pre_decision_status
    else
      fetch_post_decision_status
    end
  end

  def fetch_pre_decision_status
    if pending_schedule_hearing_task?
      :pending_hearing_scheduling
    elsif hearing_pending?
      :scheduled_hearing
    elsif evidence_submission_hold_pending?
      :evidentiary_period
    elsif at_vso?
      :at_vso
    elsif distributed_to_a_judge?
      :decision_in_progress
    else
      :on_docket
    end
  end

  def fetch_post_decision_status
    if remand_supplemental_claims.any?
      active_remanded_claims? ? :ama_remand : :post_bva_dta_decision
    elsif effectuation_ep? && !active_effectuation_ep?
      :bva_decision_effectuation
    elsif decision_issues.any?
      # there is a period of time where there are decision issues but no
      # decision document and the decisions issues do not have decision date yet
      # wait until the document is available before showing there is a decision
      decision_document ? :bva_decision : :decision_in_progress
    elsif withdrawn?
      :withdrawn
    else
      :other_close
    end
  end

  def fetch_details_for_status
    case fetch_status
    when :bva_decision
      {
        issues: api_issues_for_status_details_issues(decision_issues)
      }
    when :ama_remand
      {
        issues: api_issues_for_status_details_issues(decision_issues)
      }
    when :post_bva_dta_decision
      post_bva_dta_decision_status_details
    when :bva_decision_effectuation
      {
        bva_decision_date: decision_event_date,
        aoj_decision_date: decision_effectuation_event_date
      }
    when :pending_hearing_scheduling
      {
        type: "video"
      }
    when :scheduled_hearing
      api_scheduled_hearing_status_details
    when :decision_in_progress
      {
        decision_timeliness: AppealSeries::DECISION_TIMELINESS.dup
      }
    else
      {}
    end
  end

  def post_bva_dta_decision_status_details
    issue_list = remanded_sc_decision_issues
    {
      issues: api_issues_for_status_details_issues(issue_list),
      bva_decision_date: decision_event_date,
      aoj_decision_date: remand_decision_event_date
    }
  end

  def api_issues_for_status_details_issues(issue_list)
    issue_list.map do |issue|
      {
        description: issue.api_status_description,
        disposition: issue.api_status_disposition
      }
    end
  end

  def api_scheduled_hearing_status_details
    {
      type: api_scheduled_hearing_type,
      date: scheduled_hearing.scheduled_for.to_date,
      location: scheduled_hearing.try(:hearing_location).try(&:name)
    }
  end

  def scheduled_hearing
    # Appeal Status api assumes that there can be multiple hearings that have happened in the past but only
    # one that is currently scheduled. Will get this by getting the hearing whose scheduled date is in the future.
    @scheduled_hearing ||= hearings.find { |hearing| hearing.scheduled_for >= Time.zone.today }
  end

  def api_scheduled_hearing_type
    return unless scheduled_hearing

    hearing_types_for_status_details = {
      V: "video",
      C: "central_office"
    }.freeze

    hearing_types_for_status_details[scheduled_hearing.request_type.to_sym]
  end

  def remanded_sc_decision_issues
    issue_list = []
    remand_supplemental_claims.each do |sc|
      sc.decision_issues.map do |di|
        issue_list << di
      end
    end

    issue_list
  end

  def pending_schedule_hearing_task?
    tasks.open.where(type: ScheduleHearingTask.name).any?
  end

  def hearing_pending?
    scheduled_hearing.present?
  end

  def evidence_submission_hold_pending?
    tasks.open.where(type: EvidenceSubmissionWindowTask.name).any?
  end

  def at_vso?
    # This task is always open, this can be used once that task is completed
    # tasks.open.where(type: InformalHearingPresentationTask.name).any?
  end

  def distributed_to_a_judge?
    tasks.any? { |t| t.is_a?(JudgeTask) }
  end

  def alerts
    # " || 0" sorts all alerts (like scheduled_hearing alerts) that do not have decisionDates first.
    @alerts ||= ApiStatusAlerts.new(decision_review: self).all.sort_by { |alert| alert[:details][:decisionDate] || 0 }
  end

  def aoj
    return if request_issues.empty?

    return "other" unless all_request_issues_same_aoj?

    request_issues.first.api_aoj_from_benefit_type
  end

  def all_request_issues_same_aoj?
    request_issues.all? do |ri|
      ri.api_aoj_from_benefit_type == request_issues.first.api_aoj_from_benefit_type
    end
  end

  def all_request_issues_same_aoj?
    request_issues.all? do |ri|
      ri.api_aoj_from_benefit_type == request_issues.first.api_aoj_from_benefit_type
    end
  end

  def program
    return if request_issues.empty?

    if request_issues.all? { |ri| ri.benefit_type == request_issues.first.benefit_type }
      request_issues.first.benefit_type
    else
      "multiple"
    end
  end

  def docket_hash
    return unless active_status?
    return if location == "aoj"

    {
      type: fetch_docket_type,
      month: Date.parse(receipt_date.to_s).change(day: 1),
      switchDueDate: docket_switch_deadline,
      eligibleToSwitch: eligible_to_switch_dockets?
    }
  end

  def fetch_docket_type
    api_values = {
      "direct_review" => "directReview",
      "hearing" => "hearingRequest",
      "evidence_submission" => "evidenceSubmission"
    }

    api_values[docket_name]
  end

  def docket_switch_deadline
    @docket_switch_deadline ||= build_docket_switch_deadline
  end

  def build_docket_switch_deadline
    return unless receipt_date
    return unless request_issues.active_or_ineligible.any?
    return if request_issues.active_or_ineligible.any? { |ri| ri.decision_or_promulgation_date.nil? }

    oldest = request_issues.active_or_ineligible.min_by(&:decision_or_promulgation_date)
    deadline_from_oldest_request_issue = oldest.decision_or_promulgation_date + 365.days
    deadline_from_receipt = receipt_date + 60.days

    [deadline_from_receipt, deadline_from_oldest_request_issue].max
  end

  def eligible_to_switch_dockets?
    return false unless docket_switch_deadline

    # TODO: false if hearing already taken place, to be implemented
    # https://github.com/department-of-veterans-affairs/caseflow/issues/9205
    Time.zone.today < docket_switch_deadline
  end

  def first_distributed_to_judge_date
    judge_tasks = tasks.select { |t| t.is_a?(JudgeTask) }
    return unless judge_tasks.any?

    judge_tasks.min_by(&:created_at).created_at.to_date
  end

  def effectuation_ep?
    decision_document&.end_product_establishments&.any?
  end

  def decision_effectuation_event_date
    return unless effectuation_ep?
    return if active_effectuation_ep?

    decision_document.end_product_establishments.first.last_synced_at.to_date
  end

  def other_close_event_date
    return if active_status?
    return if decision_issues.any?

    root_task.closed_at&.to_date
  end

  def events
    @events ||= AppealEvents.new(appeal: self).all
  end

  def cavc_due_date
    decision_event_date + 120.days if decision_event_date
  end

  def available_review_options
    return ["cavc"] if request_issues.any? { |ri| ri.benefit_type == "fiduciary" }

    %w[supplemental_claim cavc]
  end
end
