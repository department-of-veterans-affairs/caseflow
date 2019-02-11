class HearingRequestDocket < Docket
  def docket_type
    "hearing"
  end

  # CMGTODO: age_of_n_oldest_priority_appeals should be reimplemented here
  # to only return genpop appeals.

  # CMGTODO
  def distribute_appeals(distribution, priority, genpop: "any", limit: 1); end
end
