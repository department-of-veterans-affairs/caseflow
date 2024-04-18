# frozen_string_literal: true

class ChangeHistoryFilterParser
  attr_reader :filter_params

  def initialize(filter_params)
    @filter_params = filter_params
  end

  def parse_filters
    {
      report_type: filter_params[:report_type],
      events: events_filter_helper,
      task_status: task_status_filter_helper,
      status_report_type: filter_params[:status_report_type],
      claim_type: filter_params[:decision_review_type]&.values,
      personnel: filter_params[:personnel]&.values,
      dispositions: disposition_filter_helper,
      issue_types: filter_params[:issue_type]&.values,
      facilities: filter_params[:facility]&.values,
      timing: filter_params[:timing].to_h,
      days_waiting: days_waiting_filter_helper
    }.deep_transform_keys(&:to_sym)
  end

  private

  def events_filter_helper
    event_mapping = {
      "added_decision_date" => :added_decision_date,
      "added_issue" => :added_issue,
      "added_issue_no_decision_date" => :added_issue_without_decision_date,
      "claim_created" => :claim_creation,
      "claim_closed" => [:completed, :cancelled],
      "claim_status_incomplete" => :incomplete,
      "claim_status_inprogress" => :in_progress,
      "completed_disposition" => :completed_disposition,
      "removed_issue" => :removed_issue,
      "withdrew_issue" => :withdrew_issue,
      "claim_cancelled" => :cancelled
    }

    filter_params[:events]&.values&.map { |event_type| event_mapping[event_type] }&.flatten
  end

  def task_status_filter_helper
    status_mapping = {
      "incomplete" => "on_hold",
      "in_progress" => %w[assigned in_progress],
      "completed" => "completed",
      "cancelled" => "cancelled"
    }

    filter_params[:statuses]&.values&.map { |task_status| status_mapping[task_status] }&.flatten
  end

  def disposition_filter_helper
    disposition_mapping = {
      "granted" => "Granted",
      "Granted" => "Granted",
      "denied" => "Denied",
      "Denied" => "Denied",
      "dta_error" => "DTA Error",
      "DTA ERROR" => "DTA Error",
      "dismissed" => "Dismissed",
      "Dismissed" => "Dismissed",
      "withdrawn" => "Withdrawn",
      "Withdrawn" => "Withdrawn",
      "blank" => "Blank",
      "Blank" => "Blank"
    }

    filter_params[:issue_disposition]&.values&.map { |disposition| disposition_mapping[disposition] }
  end

  # :reek:FeatureEnvy
  def days_waiting_filter_helper
    operator_mapping = {
      "lessThan" => "<",
      "moreThan" => ">",
      "equalTo" => "=",
      "between" => "between"
    }

    days_waiting_hash = filter_params[:days_waiting].to_h

    # Map the operator into something that SQL can understand
    operator = days_waiting_hash["comparison_operator"]
    if operator.present?
      days_waiting_hash["comparison_operator"] = operator_mapping[operator]
    end

    # Transform the keys to conform to what the service and query expects
    key_changes = { "comparison_operator" => :operator, "value_one" => :number_of_days, "value_two" => :end_days }

    days_waiting_hash.transform_keys { |key| key_changes[key] || key }
  end
end
