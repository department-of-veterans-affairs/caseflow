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
    :added_issue_without_decision_date,
    :in_progress,
    :completed,
    :incomplete,
    :cancelled
  ].freeze

  REQUEST_ISSUE_TIME_WINDOW = 15
  STATUS_EVENT_TIME_WINDOW = 2

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

    # rubocop:disable Metrics/MethodLength
    def create_status_events(change_data)
      status_events = []
      versions = parse_versions(change_data)

      hookless_cancelled_events = handle_hookless_cancelled_status_events(versions, change_data)
      status_events.push(*hookless_cancelled_events)

      if versions.present?
        first_version, *rest_of_versions = versions

        # Assume that if the dates are equal then it should be a assigned -> on_hold status event that is recorded
        # Due to the way intake is processed a task is always created as assigned first
        time_difference = (first_version["updated_at"][0] - first_version["updated_at"][1]).to_f.abs

        # If the time difference is > than 2 seconds then assume it is a valid status change instead of the
        # Normal intake assigned -> on_hold that will happen for no decision date HLR/SC intakes
        if time_difference > STATUS_EVENT_TIME_WINDOW
          status_events.push event_from_version(first_version, 0, change_data)
        end

        status_events.push event_from_version(first_version, 1, change_data)

        rest_of_versions.map do |version|
          status_events.push event_from_version(version, 1, change_data)
        end
      elsif hookless_cancelled_events.empty?
        # No versions so make an event with the current status
        # There is a chance that a task has no intake either through data setup or through a remanded SC
        event_date = change_data["intake_completed_at"] || change_data["task_created_at"]
        status_events.push from_change_data(task_status_to_event_type(change_data["task_status"]),
                                            change_data.merge("event_date" => event_date,
                                                              "event_user_name" => "System"))
      end

      # cleanup_status_event_duplicates!(hookless_cancelled_events, status_events)

      status_events
    end
    # rubocop:enable Metrics/MethodLength

    def parse_versions(change_data)
      versions = change_data["task_versions"]
      if versions
        # Quite a bit faster but less safe. Should probably be fine since it's coming from the database
        # rubocop:disable Security/YAMLLoad
        versions[1..-2].split(",").map { |yaml| YAML.load(yaml.gsub(/^"|"$/, "")) }
        # versions[1..-2].split(",").map { |yaml| YAML.safe_load(yaml.gsub(/^"|"$/, ""), [Time]) }
        # rubocop:enable Security/YAMLLoad

      end
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
      # Try to guess if it added during intake. If not, it was a probably added during an issue update
      same_transaction = date_strings_within_seconds?(change_data["intake_completed_at"],
                                                      change_data["request_issue_created_at"],
                                                      REQUEST_ISSUE_TIME_WINDOW)
      event_hash = if same_transaction
                     intake_event_hash(change_data)
                   else
                     update_event_hash(change_data).merge("event_date" => change_data["request_issue_created_at"])
                   end

      event_type = determine_add_issue_event_type(change_data)
      from_change_data(event_type, change_data.merge(event_hash))
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
        "completed" => :completed,
        "cancelled" => :cancelled
      }[task_status]
    end

    def event_from_version(changes, index, change_data)
      if changes["status"]
        event_type = task_status_to_event_type(changes["status"][index])
        event_date = changes["updated_at"][index]
        event_date_hash = { "event_date" => event_date, "event_user_name" => "System" }
        from_change_data(event_type, change_data.merge(event_date_hash))
      end
    end

    def determine_add_issue_event_type(change_data)
      # If there is no decision_date_added_at time, assume it is old data and that it had a decision date on creation
      had_decision_date = if change_data["decision_date"] && change_data["decision_date_added_at"]
                            # Assume if the time window was within 15 seconds of creation it had a decision date
                            date_strings_within_seconds?(change_data["request_issue_created_at"],
                                                         change_data["decision_date_added_at"],
                                                         REQUEST_ISSUE_TIME_WINDOW)
                          else
                            true
                          end

      had_decision_date ? :added_issue : :added_issue_without_decision_date
    end

    def intake_event_hash(change_data)
      {
        # There is a chance that a task has no intake either through data setup or through a remanded SC,
        # so include a backup event date and user name as System
        "event_date" => change_data["intake_completed_at"] || change_data["task_created_at"],
        "event_user_name" => change_data["intake_user_name"] || "System",
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

      date_difference = DateTime.iso8601(first_date.tr(" ", "T")) - DateTime.iso8601(second_date.tr(" ", "T"))

      (date_difference.abs * 24 * 60 * 60).to_f < time_in_seconds
    end

    def handle_hookless_cancelled_status_events(versions, change_data)
      # The remove reqest issues circumvents the normal paper trail hooks and results in a weird database state
      return [] unless versions

      cancelled_task_versions = versions.select { |element| element.is_a?(Hash) && element.empty? }

      return [] if cancelled_task_versions.empty?

      # Mutate the versions array and remove these empty object changes from it
      versions.reject! { |element| element.is_a?(Hash) && element.empty? }

      create_hookless_cancelled_events(versions, change_data)
    end

    def create_hookless_cancelled_events(versions, change_data)
      if versions.present?
        [
          # If there are other versions, then those will be created and used in addition to this cancelled event
          from_change_data(:cancelled, change_data.merge("event_date" => change_data["task_closed_at"],
                                                         "event_user_name" => "System"))
        ]
      else
        [
          # If there are no other versions, assume the state went from assigned -> cancelled
          from_change_data(:in_progress, change_data.merge("event_date" => change_data["intake_completed_at"] ||
                                                                            change_data["task_created_at"],
                                                           "event_user_name" => "System")),
          from_change_data(:cancelled, change_data.merge("event_date" => change_data["task_closed_at"],
                                                         "event_user_name" => "System"))
        ]
      end
    end

    def cleanup_status_event_duplicates!(hookless_events, status_events)
      # If there were hookless cancelled events do some cleanup since there's potentially an extra in progress event
      # that is caused by the handle_issues_with_no_decision_date! method in the claim_review.rb model class.
      # So if there is an incomplete event and hookless cancelled events then it's probably safe the in progress events
      # unless the state was actually on_hold -> in_progress -> cancelled which will currently not be preserved here
      if hookless_events.present? && status_events.any? { |event| event.event_type == :incomplete }
        status_events.delete_if { |event| event && event.event_type == :in_progress }
      end
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
      "completed" => "completed",
      "cancelled" => "cancelled"
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
      added_issue_without_decision_date: "Added issue - No decision date",
      withdrew_issue: "Withdrew issue",
      removed_issue: "Removed issue",
      added_decision_date: "Added decision date",
      cancelled: "Claim closed"
    }[event_type]
  end

  def issue_event?
    [
      :completed_disposition,
      :added_issue,
      :withdrew_issue,
      :removed_issue,
      :added_decision_date,
      :added_issue_without_decision_date
    ].include?(event_type)
  end

  def event_can_contain_disposition?
    [
      :completed_disposition,
      :added_issue,
      :added_issue_without_decision_date,
      :added_decision_date
    ].include?(event_type)
  end

  def disposition_event?
    event_type == :completed_disposition
  end

  def status_event?
    [:in_progress, :incomplete, :completed, :claim_creation, :cancelled].include?(event_type)
  end

  private

  def set_attributes_from_change_history_data(new_event_type, change_data)
    @event_type = new_event_type
    @claimant_name = [change_data["first_name"], " ", change_data["last_name"]].join
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
    @days_waiting = change_data["days_waiting"]
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

  def abbreviated_user_name(name_string)
    first_name, last_name = name_string.split(" ")
    name_abbreviation(first_name, last_name)
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
      claim_creation: "Claim created.",
      cancelled: "Claim closed."
    }[event_type]
  end

  def format_date_string(date)
    if date.class == String
      DateTime.iso8601(date.tr(" ", "T")).strftime("%-m/%-d/%Y")
    elsif date.present?
      date.strftime("%-m/%-d/%Y")
    end
  end

  def name_abbreviation(first_name, last_name)
    [first_name[0].capitalize, ". ", last_name].join
  end
end
