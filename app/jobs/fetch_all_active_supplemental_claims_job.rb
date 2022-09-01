# frozen_string_literal: true

# Job to fetch all currently active Supplemantal Claims
class FetchAllActiveSupplementalClaimsJob < CaseflowJob
  queue_with_priority :low_priority

  def perform
    find_active_supplemental_claims
  end

  private

  # Fetch Active Supplemantal Claims
  def find_active_supplemental_claims
    active_supplemental_claims = []
    active_supplemental_claim_tasks = Task.where(
      appeal_type: "SupplementalClaim",
      status: "assigned",
      closed_at: nil
    )
    active_supplemental_claim_tasks.each { |task| active_supplemental_claims.push(task.supplemental_claim) }
    active_supplemental_claims
  end
end
