# frozen_string_literal: true

# Job to fetch all currently active Legacy Appeals
class FetchAllActiveLegacyAppeals < CaseflowJob
  queue_with_priority :low_priority

  # Public: Calls on helper method to find all currently active legacy appeals
  # Returns an array of Legacy Appeal Objects that are currently 'Active'
  def perform
    find_active_legacy_appeals
  end

  private

  # Internal: Helper method used to find active legacy appeals.
  # This is done by searching for RootTasks with an 'Active' status that are tied to a Legacy Appeal
  # Returns an array of Legacy Appeal Objects that are currently 'Active'
  def find_active_legacy_appeals
    active_legacy_appeals = Array.new
    active_legacy_appeals_root_tasks = Task.where(
      type: "RootTask",
      appeal_type: "LegacyAppeal",
      status: %w[assigned on hold in progress],
      closed_at: nil
    )
    active_legacy_appeals_root_tasks.each do |task|
      active_legacy_appeals.push(task.appeal)
    end
    active_legacy_appeals
  end
end
