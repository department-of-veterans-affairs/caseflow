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

    # genpop 'any' returns 2 arrays of the limited base relation. This means if we only request 2 cases, appeals is a
    # 2x2 array containing 4 cases overall and we will end up distributing 4 cases rather than 2. Instead, reinstate the
    # limit here by filtering out the newest cases
    if genpop == "any"
      appeals_to_reject = appeals.flatten.sort_by(&:ready_for_distribution_at).drop(limit)
      appeals = [appeals.first - appeals_to_reject, appeals.last - appeals_to_reject]
    end

    HearingRequestCaseDistributor.new(
      appeals: appeals, genpop: genpop, distribution: distribution, priority: priority
    ).call
  end
end
