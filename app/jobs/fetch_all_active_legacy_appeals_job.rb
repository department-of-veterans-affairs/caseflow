# frozen_string_literal: true

# Job to fetch all currently active Legacy Appeals
class FetchAllActiveLegacyAppealsJob < CaseflowJob
  queue_with_priority :low_priority

  # Purpose: Job to find all active Legacy Appeals.
  #
  # Params: None
  #
  # Returns: Array of active Legacy Appeals
  def perform
    find_active_legacy_appeals
  end

  private

  # Purpose: Helper Method to build an array of Legacy Appeals that
  # have an 'Active' status (assigned/on hold/in progress).
  #
  # Params: None
  #
  # Returns: Array of active Legacy Appeals
  def find_active_legacy_appeals
    active_legacy_appeals = []
    active_legacy_appeals_root_tasks = Task.where(
      type: "RootTask",
      appeal_type: "LegacyAppeal",
      status: %w[assigned on_hold in_progress],
      closed_at: nil
    )
    active_legacy_appeals_root_tasks.each do |task|
      active_legacy_appeals.push(task.appeal)
    end
    active_legacy_appeals
  end
end
