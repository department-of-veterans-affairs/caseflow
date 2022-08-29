# frozen_string_literal: true

# Job to fetch all currently active Supplemantal Claims
class FetchAllActiveSupplementalClaimsJob < CaseflowJob
  queue_as ApplicationController.dependencies_faked? ? :send_notifications : :"send_notifications.fifo"

  def perform
    find_active_supplemental_claims
  end

  private

  def find_active_supplemental_claims
    # Fetch Active Supplemantal Claims
    active_supplemantal_claims = []
    active_supplemantal_claim_tasks = Task.where(
      appeal_type: "SupplementalClaim",
      status: %w[assigned on_hold in_progress],
      closed_at: nil
    ).uniq(&:appeal_id)
    active_supplemantal_claim_tasks.each do |task|
      active_supplemantal_claims.push(task.supplemental_claim)
    end
    active_supplemantal_claims
  end
end
