class ValidateDocketTracerNonAvailabilityUserQuotaRampElectionRollbackFk < Caseflow::Migration
  def change
  	validate_foreign_key "docket_tracers", "docket_snapshots"
    validate_foreign_key "non_availabilities", "schedule_periods"
    validate_foreign_key "user_quotas", "team_quotas"
    validate_foreign_key "ramp_election_rollbacks", "ramp_elections"
  end
end
