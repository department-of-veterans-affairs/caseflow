# frozen_string_literal: true

# Job to fetch all currently active Legacy Appeals
class FetchAllActiveAmaAppealsJob < CaseflowJob
  queue_with_priority :low_priority

  # All Variants of an IHP Task
  IHP_TYPE_TASKS = %w[IhpColocatedTask InformalHearingPresentationTask].freeze

  # Purpose: Job that finds all active AMA Appeals &
  # creates/updates records within the appeal_states table
  #
  # Params: None
  #
  # Returns: nil
  def perform
    RequestStore[:current_user ]= User.system_user
    find_and_create_appeal_state_for_active_ama_appeals
  end

  private

  # Purpose: Method that queries Database for active AMA Appeals
  # and creates/updates records within appeal_states table
  #
  # Params: None
  #
  # Returns: nil
  def find_and_create_appeal_state_for_active_ama_appeals
    Task.where(
      type: "RootTask",
      appeal_type: "Appeal",
      status: Task.open_statuses,
      closed_at: nil
    ).find_in_batches(batch_size: 1000) do |root_tasks|
      root_tasks.each do |task|
        add_record_to_appeal_states_table(task.appeal)
      end
    end
  end

  # Purpose: Method that creates/updates records within appeal_states table
  #
  # Params: Appeal or LegacyAppeal object
  #
  # Returns: nil
  def add_record_to_appeal_states_table(appeal)
    begin
      map_appeal_ihp_state(appeal)
      map_appeal_hearing_postponed_state(appeal)
    rescue StandardError => error
      Rails.logger.error("#{appeal.class} #{appeal.id} was unable to create/update appeal_states record because of "\
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
  # Returns: nil
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
  end

  def map_appeal_hearing_scheduled_state(appeal)
    # Code goes here ...
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
  end

  def map_appeal_hearing_withdrawn_state(appeal)
    # Code goes here ...
  end

  def map_appeal_hearing_scheduled_in_error_state(appeal)
    # Code goes here ...
  end

  def map_appeal_cancelled_state(appeal)
    # Code goes here ...
  end

  def map_appeal_docketed_state(appeal)
    # Code goes here ...
  end
end
