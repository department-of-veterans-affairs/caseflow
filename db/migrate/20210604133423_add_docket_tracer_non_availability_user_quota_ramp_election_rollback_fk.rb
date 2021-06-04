class AddDocketTracerNonAvailabilityUserQuotaRampElectionRollbackFk < Caseflow::Migration
  def change
    add_foreign_key "docket_tracers", "docket_snapshots", validate: false
    add_foreign_key "non_availabilities", "schedule_periods", validate: false
    add_foreign_key "user_quotas", "team_quotas", validate: false
    add_foreign_key "ramp_election_rollbacks", "ramp_elections", validate: false
  end
end
