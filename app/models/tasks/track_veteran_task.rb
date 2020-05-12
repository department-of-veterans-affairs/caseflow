# frozen_string_literal: true

##
# Task created for appellant representatives to track appeals that have been received by the Board.
# Created either when:
#   - a RootTask is created for an appeal represented by a VSO
#   - the power of attorney changes on an appeal

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

    tasks_to_sync = appeal.tasks.open.assigned_to_organization.where(
      type: [TrackVeteranTask.name, InformalHearingPresentationTask.name]
    )
    cached_representatives = tasks_to_sync.map(&:assigned_to)
    fresh_representatives = appeal.representatives
    new_representatives = fresh_representatives - cached_representatives

    # Create a TrackVeteranTask for each VSO that does not already have one.
    new_representatives.each do |new_vso|
      params = { appeal: appeal, parent: appeal.root_task, assigned_to: new_vso }
      TrackVeteranTask.create!(**params)
      new_task_count += 1

      if appeal.is_a?(Appeal) && new_vso.should_write_ihp?(appeal)
        InformalHearingPresentationTask.create!(**params)
      end
    end

    # Close all TrackVeteranTasks and InformalHearingPresentationTasks for now-former VSO representatives.
    outdated_representatives = cached_representatives - fresh_representatives
    tasks_to_sync.select { |t| outdated_representatives.include?(t.assigned_to) }.each do |task|
      task.update!(status: Constants.TASK_STATUSES.cancelled)
      task.children.open.each { |child_task| child_task.update!(status: Constants.TASK_STATUSES.cancelled) }
      closed_task_count += 1
    end

    [new_task_count, closed_task_count]
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  private

  def set_in_progress_status
    self.status = Constants.TASK_STATUSES.in_progress
  end
end
