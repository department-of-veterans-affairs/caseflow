# frozen_string_literal: true

##
# Task created for appellant representatives to track appeals that have been received by the Board.
#
# After the appeal is established, if the Veteran has a representative, a Track Veteran Task is automatically
# created and assigned to that representative so they can see their appeals. This could be an: IHP-writing VSO,
# field VSO, private attorney, or agent.
#   - If the Veteran has an IHP-writing VSO as their representative, an InformalHearingPresentationTask
#     is also automatically created and assigned.
#
# Private attorneys, agents, and field VSOs cannot create, assign, or be assigned any tasks
# (other than the TrackVeteranTask, which does not require action).
#
# Assigning this task to the representative results in the associated case appearing in their view in Caseflow.
# Created either when:
#   - a RootTask is created for an appeal represented by a VSO
#   - the power of attorney changes on an appeal
#
# See `Appeal#create_tasks_on_intake_success!` and `InitialTasksFactory.create_root_and_sub_tasks!`.

class TrackVeteranTask < Task
  # Avoid permissions errors outlined in Github ticket #9389 by setting status here.
  before_create :set_in_progress_status

  # Skip unique verification for tracking tasks since multiple VSOs may each have a tracking task and they will be
  # identified as the same organization because they both have the organization type "Vso".
  def verify_org_task_unique; end

  def available_actions(_user)
    []
  end

  def self.hide_from_queue_table_view
    true
  end

  def hide_from_case_timeline
    true
  end

  def hide_from_task_snapshot
    true
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def self.sync_tracking_tasks(appeal)
    new_task_count = 0
    closed_task_count = 0

    tasks_to_sync = appeal.tasks.open.where(
      type: [TrackVeteranTask.name, InformalHearingPresentationTask.name],
      assigned_to_type: Organization.name
    )
    cached_representatives = tasks_to_sync.map(&:assigned_to)
    fresh_representatives = appeal.representatives
    new_representatives = fresh_representatives - cached_representatives

    dist_task = appeal.tasks.open.where(type: :DistributionTask).first

    # Create a TrackVeteranTask for each VSO that does not already have one.
    new_representatives.each do |new_vso|
      params = { appeal: appeal, parent: dist_task || appeal.root_task, assigned_to: new_vso }
      TrackVeteranTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: new_vso )
      new_task_count += 1

      if appeal.is_a?(Appeal) && new_vso.should_write_ihp?(appeal)
        InformalHearingPresentationTask.create!(appeal: appeal, parent: dist_task || appeal.root_task, assigned_to: new_vso)
      end
    end

    # Close all TrackVeteranTasks and InformalHearingPresentationTasks for now-former VSO representatives.
    outdated_representatives = cached_representatives - fresh_representatives
    tasks_to_sync.select { |t| outdated_representatives.include?(t.assigned_to) }.each do |task|
      task.update!(status: Constants.TASK_STATUSES.cancelled,
                   cancellation_reason: Constants.TASK_CANCELLATION_REASONS.poa_change)
      task.children.open.each do |child_task|
        child_task.update!(status: Constants.TASK_STATUSES.cancelled,
                           cancellation_reason: Constants.TASK_CANCELLATION_REASONS.poa_change)
      end
      closed_task_count += 1
    end

    [new_task_count, closed_task_count]
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  private

  def set_in_progress_status
    self.status = Constants.TASK_STATUSES.in_progress
  end
end
