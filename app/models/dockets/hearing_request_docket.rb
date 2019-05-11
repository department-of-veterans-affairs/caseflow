# frozen_string_literal: true

class HearingRequestDocket < Docket
  def docket_type
    "hearing"
  end

  # CMGTODO: should only return genpop appeals.
  def age_of_n_oldest_priority_appeals(_num)
    []
  end

  # CMGTODO
  # rubocop:disable Lint/UnusedMethodArgument
  def distribute_appeals(_distribution, priority: false, genpop: "any", limit: 1)
    []
  end
  # rubocop:enable Lint/UnusedMethodArgument
end
