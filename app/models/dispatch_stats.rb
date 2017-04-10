class DispatchStats < Caseflow::Stats
  CALCULATIONS = {
    establish_claim_identified: lambda do |range|
      EstablishClaim.where(created_at: range).count
    end,

    establish_claim_identified_full_grant: lambda do |range|
      EstablishClaim.where(created_at: range).full_grant_tasks.count
    end,

    establish_claim_identified_partial_grant_remand: lambda do |range|
      EstablishClaim.where(created_at: range).partial_grant_remand_tasks.count
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
      EstablishClaim.where(completed_at: range).full_grant_tasks.count
    end,

    establish_claim_partial_grant_remand_completed: lambda do |range|
      EstablishClaim.where(completed_at: range).partial_grant_remand_tasks.count
    end,

    establish_claim_canceled: lambda do |range|
      EstablishClaim.where(completed_at: range).canceled.count
    end,

    establish_claim_canceled_full_grant: lambda do |range|
      EstablishClaim.where(completed_at: range).canceled.full_grant_tasks.count
    end,

    establish_claim_canceled_partial_grant_remand: lambda do |range|
      EstablishClaim.where(completed_at: range).canceled.partial_grant_remand_tasks.count
    end,

    establish_claim_completed_success: lambda do |range|
      EstablishClaim.where(completed_at: range).completed_success.count
    end,

    establish_claim_completed_success_full_grant: lambda do |range|
      EstablishClaim.where(completed_at: range).completed_success.full_grant_tasks.count
    end,

    establish_claim_completed_success_partial_grant_remand: lambda do |range|
      EstablishClaim.where(completed_at: range).completed_success.partial_grant_remand_tasks.count
    end,

    time_to_establish_claim: lambda do |range|
      DispatchStats.percentile(:time_to_establish_claim, EstablishClaim.where(completed_at: range), 95)
    end,

    median_time_to_establish_claim: lambda do |range|
      DispatchStats.percentile(:time_to_establish_claim, EstablishClaim.where(completed_at: range), 50)
    end,

    time_to_establish_claim_full_grants: lambda do |range|
      DispatchStats.percentile(:time_to_establish_claim, EstablishClaim.where(completed_at: range).full_grant_tasks, 95)
    end,

    median_time_to_establish_claim_full_grants: lambda do |range|
      DispatchStats.percentile(:time_to_establish_claim, EstablishClaim.where(completed_at: range).full_grant_tasks, 50)
    end,

    time_to_establish_claim_partial_grants_remands: lambda do |range|
      DispatchStats.percentile(:time_to_establish_claim, EstablishClaim.where(completed_at: range)
          .partial_grant_remand_tasks, 95)
    end,

    median_time_to_establish_claim_partial_grants_remands: lambda do |range|
      DispatchStats.percentile(:time_to_establish_claim, EstablishClaim.where(completed_at: range)
          .partial_grant_remand_tasks, 50)
    end
  }.freeze
end
