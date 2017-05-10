class DispatchStats < Caseflow::Stats
  CALCULATIONS = {
    establish_claim_identified: lambda do |range|
      EstablishClaim.where(created_at: range).count
    end,

    establish_claim_identified_full_grant: lambda do |range|
      EstablishClaim.where(created_at: range).for_full_grant.count
    end,

    establish_claim_identified_partial_grant_remand: lambda do |range|
      EstablishClaim.where(created_at: range).for_partial_grant_or_remand.count
    end,

    establish_claim_active_users: lambda do |range|
      EstablishClaim.where(completed_at: range).pluck(:user).uniq.count
    end,

    establish_claim_started: lambda do |range|
      EstablishClaim.where(started_at: range).count
    end,

    establish_claim_completed: lambda do |range|
      EstablishClaim.where(completed_at: range).count
    end,

    establish_claim_full_grant_completed: lambda do |range|
      EstablishClaim.where(completed_at: range).for_full_grant.count
    end,

    establish_claim_partial_grant_remand_completed: lambda do |range|
      EstablishClaim.where(completed_at: range).for_partial_grant_or_remand.count
    end,

    establish_claim_canceled: lambda do |range|
      EstablishClaim.where(completed_at: range).canceled.count
    end,

    establish_claim_canceled_full_grant: lambda do |range|
      EstablishClaim.where(completed_at: range).canceled.for_full_grant.count
    end,

    establish_claim_canceled_partial_grant_remand: lambda do |range|
      EstablishClaim.where(completed_at: range).canceled.for_partial_grant_or_remand.count
    end,

    establish_claim_completed_success: lambda do |range|
      EstablishClaim.where(completed_at: range).completed_success.count
    end,

    establish_claim_completed_success_full_grant: lambda do |range|
      EstablishClaim.where(completed_at: range).completed_success.for_full_grant.count
    end,

    establish_claim_completed_success_partial_grant_remand: lambda do |range|
      EstablishClaim.where(completed_at: range).completed_success.for_partial_grant_or_remand.count
    end,

    establish_claim_prepared: lambda do |range|
      EstablishClaim.where(prepared_at: range).count
    end,

    establish_claim_prepared_full_grant: lambda do |range|
      EstablishClaim.where(prepared_at: range).for_full_grant.count
    end,

    establish_claim_prepared_partial_grant_remand: lambda do |range|
      EstablishClaim.where(prepared_at: range).for_partial_grant_or_remand.count
    end,

    time_to_establish_claim: lambda do |range|
      DispatchStats.percentile(:time_to_complete, EstablishClaim.where(completed_at: range), 95)
    end,

    median_time_to_establish_claim: lambda do |range|
      DispatchStats.percentile(:time_to_complete, EstablishClaim.where(completed_at: range), 50)
    end,

    time_to_establish_claim_full_grants: lambda do |range|
      DispatchStats.percentile(:time_to_complete, EstablishClaim.where(completed_at: range).for_full_grant, 95)
    end,

    median_time_to_establish_claim_full_grants: lambda do |range|
      DispatchStats.percentile(:time_to_complete, EstablishClaim.where(completed_at: range).for_full_grant, 50)
    end,

    time_to_establish_claim_partial_grants_remands: lambda do |range|
      DispatchStats.percentile(:time_to_complete, EstablishClaim.where(completed_at: range)
          .for_partial_grant_or_remand, 95)
    end,

    median_time_to_establish_claim_partial_grants_remands: lambda do |range|
      DispatchStats.percentile(:time_to_complete, EstablishClaim.where(completed_at: range)
          .for_partial_grant_or_remand, 50)
    end
  }.freeze
end
