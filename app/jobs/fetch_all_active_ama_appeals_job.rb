# frozen_string_literal: true

# Job to fetch all currently active and cancelled AMA Appeals and insert records into the appeal states table
class FetchAllActiveAmaAppealsJob < CaseflowJob
  queue_with_priority :low_priority
  QUERY_LIMIT = ENV["STATE_MIGRATION_JOB_BATCH_SIZE"]

  # Purpose: Job that finds all active AMA Appeals &
  # creates records within the appeal_states table
  #
  # Params: None
  #
  # Returns: nil
  def perform
    RequestStore[:current_user] = User.system_user
    find_and_create_appeal_state_for_active_ama_appeals
  end

  private

  # Purpose: Method that queries Database for active AMA Appeals
  # and creates records within appeal_states table
  #
  # Params: None
  #
  # Returns: nil
  def find_and_create_appeal_state_for_active_ama_appeals
    Task.where(
      type: "RootTask",
      appeal_type: "Appeal",
      status: Task.open_statuses.concat([Constants.TASK_STATUSES.cancelled])
    ).find_in_batches(batch_size: QUERY_LIMIT.to_i) do |root_tasks|
      root_tasks.each do |root_task|
        add_record_to_appeal_states_table(root_task.appeal)
      end
    end
  end

  # Purpose: Method that creates records within appeal_states table
  #
  # Params: Appeal object
  #
  # Returns: nil
  def add_record_to_appeal_states_table(appeal)
    begin
      appeal_id_and_type = { appeal_id: appeal.id, appeal_type: appeal.class.to_s }
      ihp_state = map_appeal_ihp_state(appeal)
      privacy_act_state = map_appeal_privacy_act_state(appeal)
      hearing_scheduled_state = map_appeal_hearing_scheduled_state(appeal)
      hearing_postponed_state = map_appeal_hearing_postponed_state(appeal)
      hearing_withdrawn_state = map_appeal_hearing_withdrawn_state(appeal)
      hearing_scheduled_in_error_state = map_appeal_hearing_scheduled_in_error_state(appeal)
      appeal_cancelled_state = map_appeal_cancelled_state(appeal)
      appeal_docketed_state = map_appeal_docketed_state(appeal)
      # array of all appeal state hashes
      appeal_states = [appeal_id_and_type, ihp_state, privacy_act_state, hearing_scheduled_state,
                       hearing_postponed_state, hearing_withdrawn_state, hearing_scheduled_in_error_state,
                       appeal_cancelled_state, appeal_docketed_state]
      # all appeal state hash values combined
      all_appeal_states = appeal_states.inject(&:merge)
      AppealState.create(all_appeal_states)
    rescue StandardError => error
      Rails.logger.error("#{appeal&.class} ID #{appeal&.id} was unable to create an appeal_states record because of "\
         "#{error}".red)
    end
  end

  # Purpose: Updates "vso_ihp_pending" to TRUE if most recent parent IHP type task is in an open status.
  # Updates "vso_ihp_completed" to TRUE if most recent parent IHP type task has a status of 'completed'.
  #
  # Params: Most Recent Parent IHP Task (InformalHearingPresentationTask OR IhpColocatedTask)
  #
  # Returns: nil
  def update_ihp_appeal_state(ihp_task)
    appeal = ihp_task.appeal
    if Task.open_statuses.include?(ihp_task.status)
      AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "vso_ihp_pending")
    elsif [Constants.TASK_STATUSES.completed].include?(ihp_task.status)
      AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "vso_ihp_complete")
    end
  end

  # Purpose: Method that creates/updates vso_ihp_pending &
  # vso_ihp_complete records within appeal_states table
  #
  # Params: Appeal or LegacyAppeal object
  #
  # Returns: Hash of "vso_ihp_pending" & "vso_ihp_complete" key value pairs
  def map_appeal_ihp_state(appeal)
    appeal_task_types=appeal.tasks.map(&:type)
    if IHP_TYPE_TASKS.any? { |ihp_task| appeal_task_types.include?(ihp_task) }
      ihp_tasks = appeal.tasks.where(type: IHP_TYPE_TASKS)
      parent_ihp_tasks = []
      ihp_tasks.each do |task|
        if !IHP_TYPE_TASKS.include?(task&.parent&.type)
          parent_ihp_tasks.push(task)
        end
      end
      if parent_ihp_tasks.count == 1
        update_ihp_appeal_state(parent_ihp_tasks.first)
      elsif parent_ihp_tasks.count > 1
        parent_ihp_task_ids = parent_ihp_tasks.map(&:id)
        current_parent_ihp_task_id = parent_ihp_task_ids.max
        current_parent_ihp_task = Task.find current_parent_ihp_task_id
        update_ihp_appeal_state(current_parent_ihp_task)
      end
    end
  end

  def map_appeal_privacy_act_state(appeal)
    # Code goes here ...
    { privacy_act_pending: false, privacy_act_complete: false }
  end

  def map_appeal_hearing_scheduled_state(appeal)
    # Code goes here ...
    { hearing_scheduled: false }
  end

  def map_appeal_hearing_postponed_state(appeal)
    # Definition of postponed
    # All AssignHearingDispositionTasks have been cancelled
    # Another ScheduleHearingTask has been assigned OR on_hold (for admin action)
    # Will have to check disposition of last hearing to make sure that it is postponed vs scheduled_in_error

    most_recent_disposition = appeal.hearings.max_by(&:id).disposition

    # Code goes here ...
    # Get last AssignHearingDispositionTask

    # disposition_related_tasks = appeal.tasks.map do |task|
    #   task if task.type.include?("HearingDispositionTask")
    # end
    # filtered = disposition_related_tasks.compact
    # most_recent = filtered.max # most recent somehow

    if appeal.hearings.max_by(&:id).disposition == "postponed"
      AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "hearing_postponed")
    end
    { hearing_postponed: false }
  end

  def map_appeal_hearing_withdrawn_state(appeal)
    # Code goes here ...
    { hearing_withdrawn: false }
  end

  def map_appeal_hearing_scheduled_in_error_state(appeal)
    # Code goes here ...
    { scheduled_in_error: false }
  end

  def map_appeal_cancelled_state(appeal)
    # Code goes here ...
    { appeal_cancelled: false }
  end

  def map_appeal_docketed_state(appeal)
    # Code goes here ...
    { appeal_docketed: false }
  end
end
