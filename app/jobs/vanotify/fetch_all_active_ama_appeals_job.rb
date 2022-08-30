# frozen_string_literal: true

# Job to fetch all currently active AMA Appeals
class FetchAllActiveAMAAppeals < CaseflowJob
  queue_with_priority :low_priority
  
    def perform
      find_active_ama_appeals
    end

    private

    def find_active_ama_appeals
      active_ama_appeals = []
      active_ama_appeals_tasks = Task.where(
        appeal_type: "Appeal",
        status: %w[assigned on hold in progress],
        closed_at: nil
      ).uniq(&:appeal_id)
      active_ama_appeals_tasks.each do |task|
        active_ama_appeals.push(task.ama_appeal)
      end
      active_ama_appeals
    end
end
