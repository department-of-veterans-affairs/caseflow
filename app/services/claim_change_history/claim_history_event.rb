# frozen_string_literal: true

class InvalidEventType < StandardError
  def initialize(event_type)
    super("Invalid event type: #{event_type}")
  end
end

# :reek:TooManyInstanceVariables
class ClaimHistoryEvent
  attr_reader :task_id, :event_type, :event_date, :assigned_at, :days_waiting,
              :veteran_file_number, :claim_type, :claimant_name, :user_facility,
              :benefit_type, :issue_type, :issue_description, :decision_date,
              :disposition, :decision_description, :withdrawal_request_date,
              :task_status, :disposition_date, :intake_completed_date, :event_user_name,
              :event_user_css_id

  EVENT_TYPES = [
    :completed_disposition,
    :claim_creation,
    :withdrew_issue,
    :removed_issue,
    :added_decision_date,
    :added_issue,
    :in_progress,
    :completed,
    :incomplete
  ].freeze

  REQUEST_ISSUE_TIME_WINDOW = 15

  class << self
    def from_change_data(event_type, change_data)
      new(event_type, change_data)
    end

    def create_completed_disposition_event(change_data)
      if change_data["disposition"]
        event_hash = {
          "event_date" => change_data["decision_created_at"],
          "event_user_name" => change_data["decision_user_name"],
          "user_facility" => change_data["decision_user_station_id"],
          "event_user_css_id" => change_data["decision_user_css_id"]
        }
        from_change_data(:completed_disposition, change_data.merge(event_hash))
      end
    end

    def create_claim_creation_event(change_data)
      from_change_data(:claim_creation, change_data.merge(intake_event_hash(change_data)))
    end

    # This might have to change depending on performance for a lot of records
    def create_status_events(change_data)
      status_events = []
      task = Task.find(change_data["task_id"])
      versions = task.versions

      if versions.present?
        first_version, *rest_of_versions = task.versions

        # Assume that if the dates are equal then it should be a assigned -> on_hold status event that is recorded
        # Due to the way intake is processed a task is always created as assigned first
        first_changeset = first_version.changeset
        time_difference = (first_changeset["updated_at"][0] - first_changeset["updated_at"][1]).to_f.abs

        # If the time difference is > than 2 seconds then assume it is a valid status change instead of the
        # Normal intake assigned -> on_hold that will happen for no decision date HLR/SC intakes
        if time_difference > 2
          status_events.push event_from_version(first_version, 0, change_data)
        end

        status_events.push event_from_version(first_version, 1, change_data)

        rest_of_versions.map do |version|
          status_events.push event_from_version(version, 1, change_data)
        end
      else
        # No versions so make an event with the current status
        event_type = task_status_to_event_type(change_data["task_status"])
        event_hash = { "event_date" => change_data["intake_completed_at"], "event_user_name" => "System" }
        status_events.push from_change_data(event_type, change_data.merge(event_hash))
      end

      status_events
    end

    def create_issue_events(change_data)
      issue_events = []

      # before request issue ids does NOT contain withdrawn issues, but after issues does
      before_request_issue_ids = change_data["before_request_issue_ids"].scan(/\d+/).map(&:to_i)
      after_request_issue_ids = change_data["after_request_issue_ids"].scan(/\d+/).map(&:to_i)
      withdrawn_request_issue_ids = change_data["withdrawn_request_issue_ids"].scan(/\d+/).map(&:to_i)
      edited_request_issue_ids = change_data["edited_request_issue_ids"].scan(/\d+/).map(&:to_i)
      removed_request_issue_ids = (before_request_issue_ids - after_request_issue_ids)
      updates_hash = update_event_hash(change_data).merge("event_date" => change_data["request_issue_update_time"])

      # Adds all request issue events to the issue events array
      issue_events.push(*process_issue_ids(withdrawn_request_issue_ids,
                                           :withdrew_issue,
                                           change_data.merge(updates_hash)))
      issue_events.push(*process_issue_ids(removed_request_issue_ids, :removed_issue, change_data.merge(updates_hash)))
      issue_events.push(*process_issue_ids(edited_request_issue_ids, :edited_issue, change_data.merge(updates_hash)))

      issue_events
    end

    def process_issue_ids(request_issue_ids, event_type, change_data)
      created_events = []

      request_issue_ids.each do |request_issue_id|
        issue_data = retrieve_issue_data(request_issue_id)

        unless issue_data
          Rails.logger.error("No request issue found during change history generation for id: #{request_issue_id}")
          next
        end

        request_issue_data = change_data.merge(issue_data)
        if event_type == :edited_issue
          # Compare the two dates to try to guess if it was adding a decision date or not
          same_transaction = date_strings_within_seconds?(request_issue_data["decision_date_added_at"],
                                                          request_issue_data["request_issue_update_time"],
                                                          REQUEST_ISSUE_TIME_WINDOW)
          if request_issue_data["decision_date_added_at"].present? && same_transaction
            created_events.push from_change_data(:added_decision_date, request_issue_data)
          end
        else
          created_events.push from_change_data(event_type, request_issue_data)
        end
      end

      created_events
    end

    def create_add_issue_event(change_data)
      # Make a guess that it was the same transaction as intake. If not it was a probably added during an issue update
      same_transaction = date_strings_within_seconds?(change_data["intake_completed_at"],
                                                      change_data["request_issue_created_at"],
                                                      REQUEST_ISSUE_TIME_WINDOW)
      event_hash = if same_transaction
                     intake_event_hash(change_data)
                   else
                     update_event_hash(change_data).merge("event_date" => change_data["request_issue_created_at"])
                   end

      from_change_data(:added_issue, change_data.merge(event_hash))
    end

    private

    def retrieve_issue_data(request_issue_id)
      request_issue = RequestIssue.find_by(id: request_issue_id)

      if request_issue
        {
          "nonrating_issue_category" => request_issue.nonrating_issue_category,
          "nonrating_issue_description" => request_issue.nonrating_issue_description,
          "decision_date" => request_issue.decision_date,
          "decision_date_added_at" => request_issue.decision_date_added_at&.iso8601,
          "request_issue_closed_at" => request_issue.closed_at
        }
      end
    end

    def task_status_to_event_type(task_status)
      {
        "in_progress" => :in_progress,
        "assigned" => :in_progress,
        "on_hold" => :incomplete,
        "completed" => :completed
      }[task_status]
    end

    def event_from_version(version, index, change_data)
      changes = version.changeset
      if changes["status"]
        event_type = task_status_to_event_type(changes["status"][index])
        event_date = changes["updated_at"][index]
        event_date_hash = { "event_date" => event_date, "event_user_name" => "System" }
        from_change_data(event_type, change_data.merge(event_date_hash))
      end
    end

    def intake_event_hash(change_data)
      {
        "event_date" => change_data["intake_completed_at"],
        "event_user_name" => change_data["intake_user_name"],
        "user_facility" => change_data["intake_user_station_id"],
        "event_user_css_id" => change_data["intake_user_css_id"]
      }
    end

    def update_event_hash(change_data)
      {
        "event_user_name" => change_data["update_user_name"],
        "user_facility" => change_data["update_user_station_id"],
        "event_user_css_id" => change_data["update_user_css_id"]
      }
    end

    def date_strings_within_seconds?(first_date, second_date, time_in_seconds)
      return false unless first_date && second_date

      ((first_date.to_datetime - second_date.to_datetime).abs * 24 * 60 * 60).to_f < time_in_seconds
    end
  end

  ############### End of Class methods ##################

  def initialize(event_type, change_data)
    if EVENT_TYPES.include?(event_type)
      set_attributes_from_change_history_data(event_type, change_data)
    else
      fail InvalidEventType, "Invalid event type: #{event_type}"
    end
  end

  def to_csv_array
    [
      veteran_file_number, claimant_name, task_url, readable_task_status,
      days_waiting, readable_claim_type, user_facility, readable_user_name, readable_event_date,
      readable_event_type, issue_or_status_information, disposition_information
    ]
  end

  # This needs to be replaced later depending on request data or usage in the app
  def task_url
    "https://www.caseflowdemo.com/decision_reviews/vha/tasks/#{task_id}"
  end

  def readable_task_status
    {
      "assigned" => "in progress",
      "in_progress" => "in progress",
      "on_hold" => "incomplete",
      "completed" => "completed"
    }[task_status]
  end

  def readable_claim_type
    {
      "HigherLevelReview" => "Higher-Level Review",
      "SupplementalClaim" => "Supplemental Claim"
    }[claim_type]
  end

  def readable_user_name
    if event_user_name == "System"
      event_user_name
    elsif event_user_name.present?
      abbreviated_user_name(event_user_name)
    end
  end

  def readable_event_date
    format_date_string(event_date)
  end

  def readable_decision_date
    format_date_string(decision_date)
  end

  def readable_disposition_date
    format_date_string(disposition_date)
  end

  def readable_event_type
    {
      in_progress: "Claim status - In Progress",
      incomplete: "Claim status - Incomplete",
      completed: "Claim closed",
      claim_creation: "Claim created",
      completed_disposition: "Completed disposition",
      added_issue: "Added Issue",
      withdrew_issue: "Withdrew issue",
      removed_issue: "Removed issue",
      added_decision_date: "Added decision date"
    }[event_type]
  end

  def issue_event?
    [:completed_disposition, :added_issue, :withdrew_issue, :removed_issue, :added_decision_date].include?(event_type)
  end

  def event_can_contain_disposition?
    [:completed_disposition, :added_issue, :added_decision_date].include?(event_type)
  end

  def disposition_event?
    event_type == :completed_disposition
  end

  def status_event?
    [:in_progress, :incomplete, :completed, :claim_creation].include?(event_type)
  end

  private

  def set_attributes_from_change_history_data(new_event_type, change_data)
    @event_type = new_event_type

    # Pulled from the person model
    @claimant_name = FullName.new(change_data["first_name"], "", change_data["last_name"]).formatted(:readable_short)
    @event_date = change_data["event_date"]
    parse_event_attributes(change_data)
    parse_intake_attributes(change_data)
    parse_task_attributes(change_data)
    parse_issue_attributes(change_data)
    parse_disposition_attributes(change_data)
  end

  def parse_task_attributes(change_data)
    @task_id = change_data["task_id"]
    @task_status = change_data["task_status"]
    @claim_type = change_data["appeal_type"]
    @assigned_at = change_data["assigned_at"]
    @days_waiting = days_waiting_helper(change_data["assigned_at"])
  end

  def parse_intake_attributes(change_data)
    @intake_completed_date = change_data["intake_completed_at"]
    @veteran_file_number = change_data["veteran_file_number"]
  end

  def parse_issue_attributes(change_data)
    if issue_event?
      @issue_type = change_data["nonrating_issue_category"]
      @issue_description = change_data["nonrating_issue_description"]
      @decision_date = change_data["decision_date"]
      @withdrawal_request_date = change_data["request_issue_closed_at"]
    end
    @benefit_type = change_data["request_issue_benefit_type"]
  end

  def parse_disposition_attributes(change_data)
    if event_can_contain_disposition?
      @disposition = change_data["disposition"]
      @disposition_date = change_data["caseflow_decision_date"]
      @decision_description = change_data["decision_description"]
    end
  end

  def parse_event_attributes(change_data)
    standardize_event_date
    @user_facility = change_data["user_facility"]
    @event_user_name = change_data["event_user_name"]
    @event_user_css_id = change_data["event_user_css_id"]
  end

  def standardize_event_date
    # Try to keep all the dates consistent as a iso8601 string if possible
    @event_date = if event_date.is_a?(String)
                    event_date
                  else
                    event_date&.iso8601
                  end
  end

  ############ CSV and Serializer Helpers ############

  def days_waiting_helper(date_string)
    assigned_on = DateTime.parse(date_string)
    (Time.zone.today - assigned_on).to_i
  end

  def abbreviated_user_name(name_string)
    first_name, last_name = name_string.split(" ")
    FullName.new(first_name, "", last_name).formatted(:readable_fi_last_formatted)
  end

  def issue_information
    if issue_event?
      [issue_type, issue_description, readable_decision_date]
    end
  end

  def disposition_information
    if disposition_event?
      [disposition, decision_description, readable_disposition_date]
    end
  end

  def issue_or_status_information
    if status_event?
      [nil, status_description]
    else
      issue_information
    end
  end

  def status_description
    {
      in_progress: "Claim can be processed.",
      incomplete: "Claim cannot be processed until decision date is entered.",
      completed: "Claim closed.",
      claim_creation: "Claim created."
    }[event_type]
  end

  def format_date_string(date)
    if date.class == String
      Time.zone.parse(date).strftime("%-m/%-d/%Y")
    elsif date.present?
      date.strftime("%-m/%-d/%Y")
    end
  end
end
