class HearingRequestDocket < Docket
  def docket_type
    "hearing"
  end

  # CMGTODO: should only return genpop appeals.
  # rubocop:disable Lint/UnusedMethodArgument
  def age_of_n_oldest_priority_appeals(num)
    []
  end

  # CMGTODO
  def distribute_appeals(distribution, priority: false, genpop: "any", limit: 1)
    []
  end
  # rubocop:enable Lint/UnusedMethodArgument
end
