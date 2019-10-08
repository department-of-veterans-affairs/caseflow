# frozen_string_literal: true

class HearingRequestDocket < Docket
  def docket_type
    Constants.AMA_DOCKETS.hearing
  end

  def age_of_n_oldest_priority_appeals(num)
    relation = appeals(priority: true, ready: true).limit(num)

    HearingRequestDistributionQuery.new(
      base_relation: relation, genpop: "only_genpop"
    ).call.map(&:ready_for_distribution_at)
  end

  def distribute_appeals(distribution, priority: false, genpop: "any", limit: 1)
    base_relation = appeals(priority: priority, ready: true).limit(limit)

    appeals = HearingRequestDistributionQuery.new(
      base_relation: base_relation, genpop: genpop, judge: distribution.judge
    ).call

    HearingRequestCaseDistributor.new(
      appeals: appeals, genpop: genpop, distribution: distribution, priority: priority
    ).call
  end
end
