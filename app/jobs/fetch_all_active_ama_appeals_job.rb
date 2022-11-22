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
    rescue StandardError => error
      Rails.logger.error("#{appeal.class} #{appeal.id} was unable to create/update appeal_states record because of "\
         "#{error}".red)
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
        appeal = parent_ihp_tasks.first.appeal
        if Task.open_statuses.include?(parent_ihp_tasks.first.status)
          AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "vso_ihp_pending")
        elsif [Constants.TASK_STATUSES.completed].include?(parent_ihp_tasks.first.status)
          AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "vso_ihp_complete")
        end
      elsif parent_ihp_tasks.count > 1
        parent_ihp_task_ids = parent_ihp_tasks.map(&:id)
        current_parent_ihp_task_id = parent_ihp_task_ids.max
        current_parent_ihp_task = Task.find current_parent_ihp_task_id
        if Task.open_statuses.include?(current_parent_ihp_task.status)
          AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "vso_ihp_pending")
        elsif [Constants.TASK_STATUSES.completed].include?(current_parent_ihp_task.status)
          AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "vso_ihp_complete")
        end
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
    # Code goes here ...
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
