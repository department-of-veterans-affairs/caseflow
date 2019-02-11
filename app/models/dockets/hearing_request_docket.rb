class HearingRequestDocket < Docket
  def docket_type
    "hearing"
  end

  # CMGTODO: should only return genpop appeals.
  def age_of_n_oldest_priority_appeals(_num)
    []
  end

  # CMGTODO
  def distribute_appeals(_distribution, _priority, _genpop: "any", _limit: 1)
    []
  end
end
