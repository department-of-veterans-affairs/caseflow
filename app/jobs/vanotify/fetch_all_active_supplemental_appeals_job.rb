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
    active_supplemantal_claims = Task.where(
      appeal_type: "SupplementalClaim",
      status: %w[assigned on_hold in_progress],
      closed_at: nil
    )
    active_supplemantal_claims
  end
end
