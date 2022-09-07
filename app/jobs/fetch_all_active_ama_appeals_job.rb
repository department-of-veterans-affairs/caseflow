# frozen_string_literal: true

# Purpose: Job to find all active AMA Appeals.
#
# Params: None
#
# Returns: Array of active AMA Appeals
class FetchAllActiveAmaAppealsJob < CaseflowJob
  queue_with_priority :low_priority
  
  def perform
    find_active_ama_appeals
  end

    private

    # Purpose: Method to build an array of AMA Appeals that
    # are not closed and are in assigned/on hold/in progress statuses.
    #
    # Params: None
    #
    # Returns: Array of active AMA Appeals with Unique IDs (prevents duplicates)
    def find_active_ama_appeals
      active_ama_appeals = []
      active_ama_appeals_tasks = Task.where(
        appeal_type: "Appeal",
        status: %w[assigned on_hold in_progress],
        closed_at: nil
      ).uniq(&:appeal_id)
      active_ama_appeals_tasks.each { |task| active_ama_appeals.push(task.ama_appeal) }
      active_ama_appeals
    end
end
