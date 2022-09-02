# frozen_string_literal: true

# Job to fetch all currently active AMA Appeals
class FetchAllActiveAMAAppeals < CaseflowJob
  queue_with_priority :low_priority
  
    def perform
      find_active_ama_appeals
    end

    private

    #Gets an array of all active AMA Appeals
    def find_active_ama_appeals
      active_ama_appeals = []
      active_ama_appeals_tasks = Task.where(
        appeal_type: "Appeal",
        status: %w[assigned on hold in progress],
        closed_at: nil
      )
      active_ama_appeals_tasks.each { |task| active_ama_appeals.push(task.ama_appeal) }
      active_ama_appeals
    end
end
