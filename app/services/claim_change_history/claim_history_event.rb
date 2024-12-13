# frozen_string_literal: true

# :reek:TooManyInstanceVariables
# :reek:TooManyConstants
# rubocop:disable Metrics/ClassLength
class ClaimHistoryEvent
  class InvalidEventType < StandardError
    def initialize(event_type)
      super("Invalid event type: #{event_type}")
    end
  end

  attr_reader :task_id, :event_type, :event_date, :assigned_at, :days_waiting,
              :veteran_file_number, :claim_type, :claimant_name, :user_facility,
              :benefit_type, :issue_type, :issue_description, :decision_date,
              :disposition, :decision_description, :withdrawal_request_date,
              :task_status, :disposition_date, :intake_completed_date, :event_user_name,
              :event_user_css_id, :new_issue_type, :new_issue_description, :new_decision_date,
              :modification_request_reason, :request_type, :decision_reason, :decided_at_date,
              :issue_modification_request_withdrawal_date, :requestor,
              :decider, :remove_original_issue, :issue_modification_request_status,
              :previous_issue_type, :previous_issue_description, :previous_decision_date,
              :previous_modification_request_reason, :previous_withdrawal_date

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
    :cancelled,
    :pending,
    :modification,
    :addition,
    :withdrawal,
    :removal,
    :request_approved,
    :request_denied,
    :request_cancelled,
    :request_edited
  ].freeze

  ISSUE_EVENTS = [
    :completed_disposition,
    :added_issue,
    :withdrew_issue,
    :removed_issue,
    :added_decision_date,
    :added_issue_without_decision_date
  ].freeze

  DISPOSITION_EVENTS = [
    :completed_disposition,
    :added_issue,
    :added_issue_without_decision_date,
    :added_decision_date
  ].freeze

  STATUS_EVENTS = [
    :completed,
    :claim_creation,
    :cancelled,
    :in_progress,
    :incomplete,
    :pending
  ].freeze

  REQUEST_ISSUE_MODIFICATION_EVENTS = [
    :modification,
    :addition,
    :withdrawal,
    :removal,
    :request_approved,
    :request_denied,
    :request_cancelled,
    :request_edited
  ].freeze

  REQUEST_ISSUE_TIME_WINDOW = 15
  STATUS_EVENT_TIME_WINDOW = 2
  ISSUE_MODIFICATION_REQUEST_CREATION_WINDOW = 60
  # Used to signal when the database lead function is out of bounds
  OUT_OF_BOUNDS_LEAD_TIME = Time.utc(9999, 12, 31, 23, 59, 59)

  class << self
    def from_change_data(event_type, change_data)
      new(event_type, change_data)
    end

    def create_completed_disposition_event(change_data)
      if change_data["disposition"]
        event_hash = {
          "event_date" => change_data["decision_created_at"] || change_data["request_decision_created_at"],
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

    def create_issue_modification_request_event(change_data)
      issue_modification_events = []
      request_type = change_data["request_type"]
      event_hash = request_issue_modification_event_hash(change_data)

      if change_data["previous_state_array"].present?
        first_version = parse_versions(change_data["previous_state_array"])[0]
        event_hash.merge!(update_event_hash_data_from_version_object(first_version))
      end

      if request_type == "addition"
        change_data = issue_attributes_for_request_type_addition(change_data)
      end

      issue_modification_events.push from_change_data(request_type.to_sym, change_data.merge(event_hash))
    end

    def create_edited_request_issue_events(change_data)
      edited_events = []
      imr_versions = parse_versions(change_data["imr_versions"])
      previous_version = parse_versions(change_data["previous_state_array"])

      if imr_versions.present?
        *rest_of_versions, last_version = imr_versions

        if last_version["status"].present?
          edited_events.push(*create_last_version_events(change_data, last_version))
        else
          rest_of_versions.push(last_version)
        end
        edited_events.push(*create_event_from_rest_of_versions(change_data, rest_of_versions, previous_version))
      else
        create_pending_status_event(change_data, change_data["issue_modification_request_updated_at"])
      end
      edited_events
    end

    def create_event_from_rest_of_versions(change_data, edited_versions, previous_version)
      edit_of_request_events = []
      event_type = :request_edited
      event_date_hash = {}
      edited_versions.map.with_index do |version, index|
        event_date_hash = request_issue_modification_event_hash(change_data)
          .merge("event_date" => version["updated_at"][1])
        # this create_event_from_version_object updated the previous version fields in change data
        # that is being used in the front end to show the original records.
        if !previous_version[index].nil?
          event_date_hash.merge!(create_event_from_version_object(previous_version[index]))
          # this update_event_hash_data_from_version_object updates the change_data values with previous or
          # unedited data. since change_data has the final version of the data that was updated.
          # this is necessary to preserve the history that is displayed in the frontend.
          event_date_hash.merge!(update_event_hash_data_from_version_object(previous_version[index]))
        end

        event_date_hash.merge!(update_event_hash_data_from_version(version, 1))
        edit_of_request_events.push(*from_change_data(event_type, change_data.merge(event_date_hash)))
      end
      edit_of_request_events
    end

    def create_last_version_events(change_data, last_version)
      edited_events = []

      last_version["status"].map.with_index do |status, index|
        if status == "assigned"
          edited_events.push(*create_pending_status_event(change_data, last_version["updated_at"][index]))
        else
          edited_events.push(*create_request_issue_decision_events(
            change_data, last_version["updated_at"][index], status
          ))
        end
      end
      edited_events
    end

    def create_request_issue_decision_events(change_data, event_date, event)
      events = []
      event_user = change_data["decider"] || change_data["requestor"]

      decision_event_hash = pending_system_hash
        .merge("event_date" => event_date,
               "event_user_name" => event_user,
               "user_facility" => change_data["decider_station_id"] || change_data["requestor_station_id"],
               "event_user_css_id" => change_data["decider_css_id"] || change_data["requestor_css_id"])

      change_data = issue_attributes_for_request_type_addition(change_data) if change_data["request_type"] == "addition"

      request_event_type = "request_#{event}"
      events.push from_change_data(request_event_type.to_sym, change_data.merge(decision_event_hash))

      events.push create_imr_in_progress_status_event(change_data)
      events
    end

    def create_imr_in_progress_status_event(change_data)
      in_progress_system_hash_events = pending_system_hash
        .merge("event_date" => (change_data["decided_at"] ||
          change_data["issue_modification_request_updated_at"]))

      # If the imr is not decided, then always skip in progress creation
      if imr_decided_or_cancelled?(change_data) && create_imr_in_progress_status_event?(change_data)
        from_change_data(:in_progress, change_data.merge(in_progress_system_hash_events))
      end
    end

    def create_imr_in_progress_status_event?(change_data)
      # If the next imr is already decided in the same transaction, it's not in reverse order, and it's
      # not the last imr then defer creation
      return false if early_deferral?(change_data)

      if do_not_defer_in_progress_creation?(change_data)
        # If it's in reverse order and the creation of the next imr is after the current decision time then generate
        # an event since the next imr will start a new pending/in progress loop
        # Or
        # If the next created by was after the decided_at then, this was an in progress transition so create one
        # Or
        # If it's the last IMR and the next imr was decided or cancelled in the same transaction then go ahead
        # and generate an in progress event since the ordering is odd due to the decided at in the same transaction
        true
      elsif next_imr_decided_is_out_of_bounds?(change_data)
        # If it's the end of the lead rows, then this is the last decided row
        # If the next created at is in the same transaction, then defer event creation, otherwise create an in progress
        # Or
        # If the next imr was created at the same time that the current imr is decided, then defer
        create_in_progress_event_for_last_decided_by_imr?(change_data)
      elsif defer_in_progress_creation?(change_data)
        # If the next imr was in the same transaction and it's also decided, then defer event creation to it.
        # Or
        # If the next imr was created in the same transaction as the next decided, then defer to the next imr
        # Or
        # If the next imr was created at the same time that the current imr is decided, then defer
        # since it should never leave the current pending loop in that case
        false
      else
        # If nothing else matches and the next one is also decided then go ahead and generate an in progress event
        # This may occasionally result in a false positive but it should be right most of the time
        change_data["next_decided_or_cancelled_at"].present?
      end
    end

    def do_not_defer_in_progress_creation?(change_data)
      (imr_reverse_order?(change_data) && next_imr_created_by_after_current_decided_at?(change_data)) ||
        (change_data["next_decided_or_cancelled_at"].nil? &&
           next_imr_created_by_after_current_decided_at?(change_data)) ||
        (last_imr?(change_data) && next_imr_decided_or_cancelled_in_same_transaction?(change_data))
    end

    def defer_in_progress_creation?(change_data)
      (next_imr_created_in_same_transaction?(change_data) && change_data["next_decided_or_cancelled_at"]) ||
        next_imr_created_at_and_decided_at_in_same_transaction?(change_data) ||
        next_imr_created_in_same_transaction_as_decided_at?(change_data)
    end

    def imr_decided_or_cancelled?(change_data)
      %w[cancelled denied approved].include?(change_data["issue_modification_request_status"])
    end

    def next_imr_decided_or_cancelled_in_same_transaction?(change_data)
      timestamp_within_seconds?(change_data["decided_at"], change_data["next_decided_or_cancelled_at"], 2)
    end

    def next_imr_created_in_same_transaction?(change_data)
      timestamp_within_seconds?(change_data["issue_modification_request_created_at"],
                                change_data["next_created_at"],
                                2)
    end

    def next_imr_created_in_same_transaction_as_decided_at?(change_data)
      timestamp_within_seconds?(change_data["next_created_at"],
                                change_data["decided_at"],
                                2)
    end

    def next_imr_created_by_after_current_decided_at?(change_data)
      change_data["next_created_at"] &&
        change_data["decided_at"] &&
        !last_imr?(change_data) &&
        (change_data["next_created_at"].change(usec: 0) > change_data["decided_at"].change(usec: 0))
    end

    def next_imr_created_at_and_decided_at_in_same_transaction?(change_data)
      timestamp_within_seconds?(change_data["next_decided_or_cancelled_at"],
                                change_data["next_created_at"],
                                2)
    end

    def imr_reverse_order?(change_data)
      change_data["previous_imr_decided_at"].nil? || change_data["decided_at"].nil? ||
        (change_data["previous_imr_decided_at"] > change_data["decided_at"])
    end

    def next_imr_decided_is_out_of_bounds?(change_data)
      change_data["next_decided_or_cancelled_at"] == OUT_OF_BOUNDS_LEAD_TIME
    end

    def last_imr?(change_data)
      change_data["next_created_at"] == OUT_OF_BOUNDS_LEAD_TIME
    end

    def create_in_progress_event_for_last_decided_by_imr?(change_data)
      if next_imr_created_in_same_transaction?(change_data) ||
         next_imr_created_in_same_transaction_as_decided_at?(change_data)
        false
      else
        true
      end
    end

    def early_deferral?(change_data)
      next_imr_decided_or_cancelled_in_same_transaction?(change_data) &&
        !imr_reverse_order?(change_data) && !last_imr?(change_data)
    end

    def create_pending_status_event(change_data, event_date)
      pending_system_hash_events = pending_system_hash
        .merge("event_date" => event_date)

      if change_data["previous_imr_created_at"].nil?
        # If this is the first IMR then it will always generate a pending event.
        from_change_data(:pending, change_data.merge(pending_system_hash_events))
      elsif timestamp_within_seconds?(change_data["previous_imr_decided_at"],
                                      change_data["issue_modification_request_created_at"],
                                      STATUS_EVENT_TIME_WINDOW)
        # If this IMR was created at the same time as the previous decided at then skip pending event creation.
        nil
      elsif !previous_imr_created_in_same_transaction?(change_data)
        # if two imr's are of different transaction and if decision has already been made then we
        # want to put pending status since it went back to pending status before it was approved/cancelled or denied.
        from_change_data(:pending, change_data.merge(pending_system_hash_events))
      end
    end

    # rubocop:disable Metrics/MethodLength
    def create_status_events(change_data)
      status_events = []
      versions = parse_versions(change_data["task_versions"])
      hookless_cancelled_events = handle_hookless_cancelled_status_events(versions, change_data)
      status_events.push(*hookless_cancelled_events)

      if versions.present?
        first_version, *rest_of_versions = versions

        # Assume that if the dates are equal then it should be a assigned -> on_hold status event that is recorded
        # Due to the way intake is processed a task is always created as assigned first
        # If the time difference is > than 2 seconds then assume it is a valid status change instead of the
        # Normal intake assigned -> on_hold that will happen for no decision date HLR/SC intakes
        if !timestamp_within_seconds?(first_version["updated_at"][0],
                                      first_version["updated_at"][1],
                                      STATUS_EVENT_TIME_WINDOW)
          status_events.push event_from_version(first_version, 0, change_data)
        end

        status_events.push event_from_version(first_version, 1, change_data)

        rest_of_versions.map do |version|
          status_events.push event_from_version(version, 1, change_data)
        end

        # If there are no events, then it had versions but none that altered status so create one from current status
        status_events.compact!
        if status_events.empty?
          status_events.push create_status_event_from_current_status(change_data)
        end
      elsif hookless_cancelled_events.empty?
        # No versions so make an event with the current status
        status_events.push create_status_event_from_current_status(change_data)
      end

      status_events
    end
    # rubocop:enable Metrics/MethodLength

    def create_status_event_from_current_status(change_data)
      # There is a chance that a task has no intake either through data setup or through a remanded SC
      from_change_data(task_status_to_event_type(change_data["task_status"]),
                       change_data.merge("event_date" => change_data["intake_completed_at"] ||
                                                         change_data["task_created_at"],
                                         "event_user_name" => "System"))
    end

    def parse_versions(versions)
      # Quite a bit faster but less safe. Should probably be fine since it's coming from the database
      # rubocop:disable Security/YAMLLoad
      # versions&.split("|||")&.map { |yaml| YAML.load(yaml.gsub(/^"|"$/, "")) }
      versions&.split("|||")&.map { |yaml| YAML.load(yaml) }
      # rubocop:enable Security/YAMLLoad
    end

    def create_issue_events(change_data)
      issue_events = []
      before_request_issue_ids = extract_issue_ids_from_change_data(change_data, "before_request_issue_ids")
      after_request_issue_ids = extract_issue_ids_from_change_data(change_data, "after_request_issue_ids")
      withdrawn_request_issue_ids = extract_issue_ids_from_change_data(change_data, "withdrawn_request_issue_ids")
      edited_request_issue_ids = extract_issue_ids_from_change_data(change_data, "edited_request_issue_ids")
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

    def issue_attributes_for_request_type_addition(change_data)
      # addition should not have issue_type that is pre-existing
      issue_data = {
        "nonrating_issue_category" => nil,
        "nonrating_issue_description" => nil,
        "decision_date" => nil
      }

      change_data.merge(issue_data)
    end

    def previous_imr_created_in_same_transaction?(change_data)
      timestamp_within_seconds?(change_data["issue_modification_request_created_at"],
                                change_data["previous_imr_created_at"] ||
                                change_data["issue_modification_request_created_at"],
                                ISSUE_MODIFICATION_REQUEST_CREATION_WINDOW)
    end

    def extract_issue_ids_from_change_data(change_data, key)
      (change_data[key] || "").scan(/\d+/).map(&:to_i)
    end

    def decider_user_facility(change_data)
      change_data["decider_station_id"] || change_data["requestor_station_id"]
    end

    def process_issue_ids(request_issue_ids, event_type, change_data)
      created_events = []

      request_issue_ids.each do |request_issue_id|
        issue_data = retrieve_issue_data(request_issue_id, change_data)

        unless issue_data
          Rails.logger.error("No request issue found during change history generation for id: #{request_issue_id}")
          next
        end

        request_issue_data = change_data.merge(issue_data)
        if event_type == :edited_issue
          # Compare the two dates to try to guess if it was adding a decision date or not
          same_transaction = timestamp_within_seconds?(request_issue_data["decision_date_added_at"],
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
      # Try to guess if it was added during intake. If not, it was a probably added during an issue update
      same_transaction = timestamp_within_seconds?(change_data["intake_completed_at"],
                                                   change_data["request_issue_created_at"],
                                                   REQUEST_ISSUE_TIME_WINDOW)
      # If it was during intake or if there's no request issue update time then use the intake event hash
      # This will also catch most request issues that were added to claims that don't have an intake
      event_hash = if same_transaction || !change_data["request_issue_update_time"]
                     intake_event_hash(change_data)
                   else
                     # try to guess the request issue update user data
                     add_issue_update_event_hash(change_data)
                   end

      event_type = determine_add_issue_event_type(change_data)
      from_change_data(event_type, change_data.merge(event_hash))
    end

    private

    def retrieve_issue_data(request_issue_id, change_data)
      # If the request issue id is the same as the database row that is being parsed, then skip the database fetch
      return {} if change_data["request_issue_id"] == request_issue_id

      # Manually try to fetch the request issue from the database
      request_issue = RequestIssue.find_by(id: request_issue_id)

      if request_issue
        {
          "nonrating_issue_category" => request_issue.nonrating_issue_category,
          "nonrating_issue_description" => request_issue.nonrating_issue_description ||
            request_issue.unidentified_issue_text,
          "decision_date" => request_issue.decision_date,
          "decision_date_added_at" => request_issue.decision_date_added_at,
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
        "cancelled" => :cancelled,
        "pending" => :pending
      }[task_status]
    end

    def update_event_hash_data_from_version(version, index)
      version_database_field_mapping.each_with_object({}) do |(version_key, db_key), data|
        data[db_key] = version[version_key][index] unless version[version_key].nil?
      end
    end

    def update_event_hash_data_from_version_object(version)
      version_database_field_mapping.each_with_object({}) do |(version_key, db_key), data|
        data[db_key] = version[version_key]
      end
    end

    def create_event_from_version_object(version)
      previous_version_database_field_mapping.each_with_object({}) do |(version_key, db_key), data|
        data[db_key] = version[version_key]
      end
    end

    def event_from_version(changes, index, change_data)
      # If there is no task status change in the set of papertrail changes, ignore the object
      if changes["status"]
        event_type = task_status_to_event_type(changes["status"][index])
        event_date_hash = { "event_date" => changes["updated_at"][index], "event_user_name" => "System" }
        from_change_data(event_type, change_data.merge(event_date_hash))
      end
    end

    def determine_add_issue_event_type(change_data)
      # If there is no decision_date_added_at time, assume it is old data and that it had a decision date on creation
      had_decision_date = if change_data["decision_date"] && change_data["decision_date_added_at"]
                            # Assume if the time window was within 15 seconds of creation that it had a decision date
                            timestamp_within_seconds?(change_data["request_issue_created_at"],
                                                      change_data["decision_date_added_at"],
                                                      REQUEST_ISSUE_TIME_WINDOW)
                          elsif change_data["decision_date"].blank?
                            false
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

    def version_database_field_mapping
      {
        "nonrating_issue_category" => "requested_issue_type",
        "nonrating_issue_description" => "requested_issue_description",
        "remove_original_issue" => "remove_original_issue",
        "request_reason" => "modification_request_reason",
        "decision_date" => "requested_decision_date",
        "decision_reason" => "decision_reason",
        "withdrawal_date" => "issue_modification_request_withdrawal_date"
      }
    end

    def previous_version_database_field_mapping
      {
        "nonrating_issue_category" => "previous_issue_type",
        "nonrating_issue_description" => "previous_issue_description",
        "decision_date" => "previous_decision_date",
        "request_reason" => "previous_modification_request_reason",
        "withdrawal_date" => "previous_withdrawal_date"
      }
    end

    def add_issue_update_event_hash(change_data)
      # Check the current request issue updates time to see if the issue update is in the correct row
      # If it is, then do the normal update_event_hash information
      if timestamp_within_seconds?(change_data["request_issue_created_at"],
                                   change_data["request_issue_update_time"],
                                   REQUEST_ISSUE_TIME_WINDOW)
        update_event_hash(change_data).merge("event_date" => change_data["request_issue_created_at"])
      else
        # If it's not, then do some database fetches to grab the correct information
        retrieve_issue_update_data(change_data)
      end
    end

    def retrieve_issue_update_data(change_data)
      # This DB fetch is gross, but thankfully it should happen very rarely
      task = Task.includes(appeal: { request_issues_updates: :user }).where(id: change_data["task_id"]).first
      issue_update = task.appeal.request_issues_updates.find do |update|
        (update.after_request_issue_ids - update.before_request_issue_ids).include?(change_data["request_issue_id"])
      end
      if issue_update
        {
          "event_date" => change_data["request_issue_created_at"],
          "event_user_name" => issue_update.user&.full_name,
          "user_facility" => issue_update.user&.station_id,
          "event_user_css_id" => issue_update.user&.css_id
        }
      # If for some reason there was no match, then just default to the row that already exists in the change data
      else
        update_event_hash(change_data).merge("event_date" => change_data["request_issue_created_at"])
      end
    end

    def request_issue_modification_event_hash(change_data)
      {
        "event_date" => change_data["issue_modification_request_created_at"],
        "event_user_name" => change_data["requestor"],
        "user_facility" => change_data["requestor_station_id"],
        "event_user_css_id" => change_data["requestor_css_id"]
      }
    end

    def pending_system_hash
      {
        "event_user_name" => "System",
        "event_type" => "in_progress"
      }
    end

    def timestamp_within_seconds?(first_date, second_date, time_in_seconds)
      return false unless first_date && second_date

      # Less variables for less garbage collection since this method is used a lot
      (first_date - second_date).abs < time_in_seconds
    end

    def handle_hookless_cancelled_status_events(versions, change_data)
      # The remove request issues circumvents the normal paper trail hooks and results in a weird database state
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
      days_waiting, readable_claim_type, readable_facility_name, readable_user_name, readable_event_date,
      readable_event_type, issue_or_status_information, issue_modification_request_information, disposition_information
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
      "cancelled" => "cancelled",
      "pending" => "pending"
    }[task_status]
  end

  def readable_claim_type
    {
      "HigherLevelReview" => "Higher-Level Review",
      "SupplementalClaim" => "Supplemental Claim",
      "Remand" => "Remand"
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

  def readable_new_decision_date
    format_date_string(new_decision_date)
  end

  def readable_disposition_date
    format_date_string(disposition_date)
  end

  def readable_facility_name
    return "" unless user_facility

    [Constants::BGS_FACILITY_CODES[user_facility], " (", user_facility, ")"].join
  end

  # rubocop:disable Metrics/MethodLength
  def readable_event_type
    {
      in_progress: "Claim status - In progress",
      incomplete: "Claim status - Incomplete",
      pending: "Claim status - Pending",
      completed: "Claim closed",
      claim_creation: "Claim created",
      completed_disposition: "Completed disposition",
      added_issue: "Added issue",
      added_issue_without_decision_date: "Added issue - No decision date",
      withdrew_issue: "Withdrew issue",
      removed_issue: "Removed issue",
      added_decision_date: "Added decision date",
      cancelled: "Claim closed",
      addition: "Requested issue addition",
      removal: "Requested issue removal",
      modification: "Requested issue modification",
      withdrawal: "Requested issue withdrawal",
      request_approved: "Approval of request - issue #{request_type}",
      request_denied: "Rejection of request - issue #{request_type}",
      request_cancelled: "Cancellation of request",
      request_edited: "Edit of request - issue #{request_type}"
    }[event_type]
  end
  # rubocop:enable Metrics/MethodLength

  def issue_event?
    ISSUE_EVENTS.include?(event_type)
  end

  def event_can_contain_disposition?
    DISPOSITION_EVENTS.include?(event_type)
  end

  def disposition_event?
    event_type == :completed_disposition
  end

  def status_event?
    STATUS_EVENTS.include?(event_type)
  end

  def event_has_modification_request?
    REQUEST_ISSUE_MODIFICATION_EVENTS.include?(event_type)
  end

  private

  def set_attributes_from_change_history_data(new_event_type, change_data)
    @event_type = new_event_type
    @claimant_name = change_data["claimant_name"]
    @event_date = change_data["event_date"]
    parse_event_attributes(change_data)
    parse_intake_attributes(change_data)
    parse_task_attributes(change_data)
    parse_issue_attributes(change_data)
    parse_disposition_attributes(change_data)
    parse_request_issue_modification_attributes(change_data)
  end

  def parse_task_attributes(change_data)
    @task_id = change_data["task_id"]
    @task_status = derive_task_status(change_data)
    @claim_type = change_data["type_classifier"]
    @assigned_at = change_data["assigned_at"]
    @days_waiting = change_data["days_waiting"]
  end

  def derive_task_status(change_data)
    change_data["is_assigned_present"] ? "pending" : change_data["task_status"]
  end

  def parse_intake_attributes(change_data)
    @intake_completed_date = change_data["intake_completed_at"]
    @veteran_file_number = change_data["veteran_file_number"]
  end

  def parse_issue_attributes(change_data)
    if issue_event? || event_has_modification_request?
      @issue_type = change_data["nonrating_issue_category"]
      @issue_description = change_data["nonrating_issue_description"] || change_data["unidentified_issue_text"]
      @decision_date = change_data["decision_date"]
      @withdrawal_request_date = change_data["request_issue_closed_at"]
    end
    @benefit_type = change_data["request_issue_benefit_type"]
  end

  def parse_disposition_attributes(change_data)
    if event_can_contain_disposition?
      @disposition = change_data["disposition"]
      @decision_description = change_data["decision_description"]
    end
    # The disposition date is also used for the completed status event on the HistoryPage UI
    @disposition_date = change_data["caseflow_decision_date"]
  end

  def parse_event_attributes(change_data)
    @user_facility = change_data["user_facility"]
    @event_user_name = change_data["event_user_name"]
    @event_user_css_id = change_data["event_user_css_id"]
  end

  def parse_request_issue_modification_attributes(change_data)
    if event_has_modification_request?
      @request_type = change_data["request_type"]
      @new_issue_type = change_data["requested_issue_type"]
      @new_issue_description = change_data["requested_issue_description"]
      @new_decision_date = change_data["requested_decision_date"]
      @modification_request_reason = change_data["modification_request_reason"]
      @decision_reason = change_data["decision_reason"]
      @decided_at_date = change_data["decided_at"]
      @issue_modification_request_withdrawal_date = change_data["issue_modification_request_withdrawal_date"]
      @remove_original_issue = change_data["remove_original_issue"]
      @issue_modification_request_status = change_data["issue_modification_request_status"]
      @requestor = change_data["requestor"]
      @decider = change_data["decider"]
      parse_previous_issue_modification_attributes(change_data)
    end
  end

  def parse_previous_issue_modification_attributes(change_data)
    @previous_issue_type = derive_previous_issue_type(change_data)
    @previous_decision_date = derive_previous_decision_date(change_data)
    @previous_modification_request_reason = derive_previous_modification_request_reason(change_data)
    @previous_issue_description = derive_previous_issue_description(change_data)
    @previous_withdrawal_date = derive_previous_withdrawal_date(change_data)
  end

  def derive_previous_issue_type(change_data)
    change_data["previous_issue_type"] || change_data["requested_issue_type"]
  end

  def derive_previous_decision_date(change_data)
    change_data["previous_decision_date"] || change_data["requested_decision_date"]
  end

  def derive_previous_issue_description(change_data)
    change_data["previous_issue_description"] || change_data["requested_issue_description"]
  end

  def derive_previous_modification_request_reason(change_data)
    change_data["previous_modification_request_reason"] || change_data["modification_request_reason"]
  end

  def derive_previous_withdrawal_date(change_data)
    change_data["previous_withdrawal_date"] || change_data["issue_modification_request_withdrawal_date"]
  end

  ############ CSV and Serializer Helpers ############

  def abbreviated_user_name(name_string)
    first_name, last_name = name_string.split(" ")
    name_abbreviation(first_name, last_name)
  end

  def issue_information
    if issue_event? || event_has_modification_request?
      [issue_type, issue_description, readable_decision_date]
    end
  end

  def issue_modification_request_information
    if event_has_modification_request?
      [new_issue_type, new_issue_description, readable_new_decision_date, modification_request_reason, decision_reason]
    else
      [nil, nil, nil, nil, nil]
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
      cancelled: "Claim cancelled.",
      pending: "Claim cannot be processed until VHA admin reviews pending requests."
    }[event_type]
  end

  def format_date_string(date)
    if date.class == String
      DateTime.iso8601(date).strftime("%-m/%-d/%Y")
    elsif date.present?
      date.strftime("%-m/%-d/%Y")
    end
  end

  def name_abbreviation(first_name, last_name)
    [first_name[0].capitalize, ". ", last_name].join
  end
end
# rubocop:enable Metrics/ClassLength
