# frozen_string_literal: true

class InvalidEventType < StandardError
  def initialize(event_type)
    super("Invalid event type: #{event_type}")
  end
end

class ClaimHistoryEvent
  attr_reader :task_id, :event_type, :event_date, :assigned_at, :days_waiting,
              :veteran_file_number, :claim_type, :claimant_name, :user_facility,
              :benefit_type, :issue_type, :issue_description, :decision_date,
              :disposition, :decision_description, :withdrawal_request_date,
              :task_status, :disposition_date, :intake_completed_date, :event_user_name,
              :event_user_id

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

  class << self
    def from_change_data(event_type, change_data)
      # if EVENT_TYPES.include?(event_type)
      #   new(event_type, change_data)
      # else
      #   fail InvalidEventType, "Invalid event type: #{event_type}"
      # end
      new(event_type, change_data)
    end

    # TODO: There's no good way to determine who completed a disposition
    # There's task.completed_by but it's not being used on dispositions. It also won't be present for past data unless
    # We could run a job/script to backfill this to the whodunnit on task versions for status -> completed
    def create_completed_disposition_event(change_data)
      if change_data["disposition"]
        event_hash = {
          "event_date" => change_data["decision_created_at"],
          "event_user_name" => change_data["decision_user_name"],
          "user_facility" => change_data["decision_user_station_id"],
          "event_user_id" => change_data["decision_user_id"]
        }
        from_change_data(:completed_disposition, change_data.merge(event_hash))
      end
    end

    def create_claim_creation_event(change_data)
      from_change_data(:claim_creation, change_data.merge(intake_event_hash(change_data)))
    end

    # TODO: This is not great since it's more DB calls inside of the loop
    # This is actually terrible. It's beyond not great
    # Might have to bulk retrieve these somehow if it is too slow. I'm pretty sure it will be.
    # Might have to do two loops of the records unfortunately and then do this and then loop over that
    # tasks = Task.where(id: array_of_task_ids).includes(:versions)
    def create_status_events(change_data)
      status_events = []
      task = Task.find(change_data["task_id"])
      versions = task.versions

      if versions.present?
        first_version, *rest_of_versions = task.versions

        # Assume that if the dates are equal then it should be a assigned -> on_hold status event that is recorded
        # Due to the way intake is processed a task is always created as assigned first
        # TODO: Is it possible to not have an updated_at time? Timecop.freeze causes this which is not good
        first_changeset = first_version.changeset
        time_difference = (first_changeset["updated_at"][0] - first_changeset["updated_at"][1]).to_f.abs
        # Old comparison
        # if first_version.changeset["updated_at"][0].round != first_version.changeset["updated_at"][1].round

        # If the time difference is > than 2 seconds then assume it is a valid status change instead of the
        # Normal intake assigned -> on_hold that will happen for no decision date
        if time_difference > 2
          status_events.push event_from_version(first_version, 0, change_data)
        end

        status_events.push event_from_version(first_version, 1, change_data)

        rest_of_versions.map do |version|
          status_events.push event_from_version(version, 1, change_data)
        end
      else
        # No versions so just make one with the current status?
        event_type = task_status_to_event_type(change_data["task_status"])
        event_hash = { "event_date" => change_data["intake_completed_at"], "event_user_name" => "System" }
        status_events.push from_change_data(event_type, change_data.merge(event_hash))
      end

      status_events
    end

    def create_issue_events(change_data)
      issue_events = []

      # TODO: before request issue ids does NOT contain withdrawn issues, but after issues does
      # This is definitely not correct
      before_request_issue_ids = change_data["before_request_issue_ids"].scan(/\d+/).map(&:to_i)
      after_request_issue_ids = change_data["after_request_issue_ids"].scan(/\d+/).map(&:to_i)
      withdrawn_request_issue_ids = change_data["withdrawn_request_issue_ids"].scan(/\d+/).map(&:to_i)
      edited_request_issue_ids = change_data["edited_request_issue_ids"].scan(/\d+/).map(&:to_i)
      removed_request_issue_ids = (before_request_issue_ids - after_request_issue_ids)

      # TODO: Pull this out into a method except event_date
      updates_hash = {
        "event_date" => change_data["request_issue_update_time"],
        "event_user_name" => change_data["update_user_name"],
        "user_facility" => change_data["update_user_station_id"],
        "event_user_id" => change_data["update_user_id"]
      }

      # Adds events to the issue events array
      # TODO: Withdrawn might need to add withdrawn date to the updates hash before sending it in
      process_issue_ids!(withdrawn_request_issue_ids, :withdrew_issue, change_data, updates_hash, issue_events)
      process_issue_ids!(removed_request_issue_ids, :removed_issue, change_data, updates_hash, issue_events)
      process_issue_ids!(edited_request_issue_ids, :edited_issue, change_data, updates_hash, issue_events)

      issue_events
    end

    # This is a mutating helper function that modifies the issue_events array parameter
    def process_issue_ids!(request_issue_ids, event_type, change_data, updates_hash, issue_events)
      request_issue_ids.each do |request_issue_id|
        issue_data = retrieve_issue_data(request_issue_id)

        unless issue_data
          Rails.logger.error("No request issue found during change history generation for id: #{request_issue_id}")
          next
        end

        request_issue_data = updates_hash.merge(issue_data)
        # TODO: Pull this date comparison out into function since it's used in two spots. It also has magic numbers
        if event_type == :edited_issue
          # Compare the two dates to try to guess if it was adding a decision date or not
          if request_issue_data["decision_date_added_at"].present? &&
             ((request_issue_data["decision_date_added_at"].to_datetime -
              change_data["request_issue_update_time"].to_datetime).abs * 24 * 60 * 60).to_f < 15
            issue_events.push from_change_data(:added_decision_date, change_data.merge(request_issue_data))
          end
        else
          issue_events.push from_change_data(event_type, change_data.merge(request_issue_data))
        end
      end
    end

    def create_add_issue_event(change_data)
      # Make a guess that it was the same transaction as intake. If not it was a probably an update
      # TODO: Verify that this date comparison is valid/good enough
      # ((Time.zone.now - 7.days - 2.hours).iso8601.to_datetime -
      # Time.zone.now.iso8601.to_datetime).abs * 24 * 60 * 60.to_f

      # TODO: Investigate if these values can ever be null or empty strings since it will syntax error
      # TODO: Move this to a helper method since it is used in two spots
      same_transaction = ((change_data["intake_completed_at"].to_datetime -
                          change_data["request_issue_created_at"].to_datetime).abs * 24 * 60 * 60).to_f < 15
      event_hash = if same_transaction
                     intake_event_hash(change_data)
                   else
                     {
                       "event_date" => change_data["request_issue_created_at"],
                       "event_user_name" => change_data["update_user_name"],
                       "user_facility" => change_data["update_user_regional_office"] ||
                         change_data["update_user_station_id"],
                       "event_user_id" => change_data["update_user_id"]
                     }
                   end

      from_change_data(:added_issue, change_data.merge(event_hash))
    end

    private

    def retrieve_issue_data(request_issue_id)
      # TODO: If this fails for some reason what do I do?
      # Example: The issue was removed so it's gone from the database now should I just return nils for the fields?
      request_issue = RequestIssue.find_by(id: request_issue_id)

      if request_issue
        {
          "nonrating_issue_category" => request_issue.nonrating_issue_category,
          "nonrating_issue_description" => request_issue.nonrating_issue_description,
          "decision_date" => request_issue.decision_date,
          "decision_date_added_at" => request_issue.decision_date_added_at&.iso8601
        }
      end
    end

    def task_status_to_event_type(task_status)
      if task_status == "in_progress" || task_status == "assigned"
        :in_progress
      elsif task_status == "on_hold"
        :incomplete
      elsif task_status == "completed"
        :completed
      end
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
        "event_user_id" => change_data["intake_user_id"]
      }
    end

    # TODO: Finish this method and use it to replace the two spots that use it
    def update_event_hash(change_data)
      {
        "event_user_name" => change_data["update_user_name"],
        "user_facility" => change_data["update_user_station_id"],
        "event_user_id" => change_data["update_user_id"]
      }
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
      @veteran_file_number, @claimant_name, task_url, readable_task_status,
      @days_waiting, readable_claim_type, @user_facility, readable_user_name, readable_event_date,
      readable_event_type, issue_or_status_information, disposition_information
    ]
  end

  # This needs to be replaced later depending on request data or usage in the app
  def task_url
    "https://www.caseflowdemo.com/decision_reviews/vha/tasks/#{@task_id}"
  end

  def readable_task_status
    {
      "assigned" => "in progress",
      "in_progress" => "in progress",
      "on_hold" => "incomplete",
      "completed" => "completed"
    }[@task_status]
  end

  def readable_claim_type
    {
      "HigherLevelReview" => "Higher-Level Review",
      "SupplementalClaim" => "Supplemental Claim"
    }[@claim_type]
  end

  def readable_user_name
    if @event_user_name == "System"
      @event_user_name
    elsif @event_user_name.present?
      abbreviated_user_name(@event_user_name)
    end
  end

  def readable_event_date
    format_date_string(@event_date)
  end

  def readable_decision_date
    format_date_string(@decision_date)
  end

  def readable_disposition_date
    format_date_string(@disposition_date)
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
    }[@event_type]
  end

  def issue_event?
    [:completed_disposition, :added_issue, :withdrew_issue, :removed_issue, :added_decision_date].include?(@event_type)
  end

  def disposition_event?
    @event_type == :completed_disposition
  end

  def status_event?
    [:in_progress, :incomplete, :completed, :claim_creation].include?(@event_type)
  end

  private

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def set_attributes_from_change_history_data(event_type, change_data)
    @event_type = event_type
    @task_id = change_data["task_id"]
    @task_status = change_data["task_status"]
    @intake_completed_date = change_data["completed_at"]
    @veteran_file_number = change_data["veteran_file_number"]
    @claim_type = change_data["appeal_type"]
    @assigned_at = change_data["assigned_at"]
    @days_waiting = days_waiting_helper(change_data["assigned_at"])

    # Pulled from the person model
    @claimant_name = FullName.new(change_data["first_name"], "", change_data["last_name"]).formatted(:readable_short)
    @issue_type = change_data["nonrating_issue_category"]
    @issue_description = change_data["nonrating_issue_description"]
    @decision_date = change_data["decision_date"]
    @benefit_type = change_data["request_issue_benefit_type"]
    @disposition = change_data["disposition"]
    @disposition_date = change_data["caseflow_decision_date"]
    @decision_description = change_data["decision_description"]

    # TODO: Should probably use event date instead of this
    @withdrawal_request_date = change_data["request_issue_update_time"]

    # Try to keep all the dates consistent as a iso8601 string if possible
    @event_date = if change_data["event_date"].is_a?(String)
                    change_data["event_date"]
                  else
                    change_data["event_date"]&.iso8601
                  end
    @user_facility = change_data["user_facility"]
    @event_user_name = change_data["event_user_name"]
    @event_user_id = change_data["event_user_id"]
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

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
      [@issue_type, @issue_description, readable_decision_date]
    end
  end

  def disposition_information
    if disposition_event?
      [@disposition, @decision_description, readable_disposition_date]
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
    }[@event_type]
  end

  def format_date_string(date)
    if date.class == String
      Time.zone.parse(date).strftime("%-m/%-d/%Y")
    elsif date.present?
      date.strftime("%-m/%-d/%Y")
    end
  end
end
