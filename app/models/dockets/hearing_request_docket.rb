# frozen_string_literal: true

class HearingRequestDocket < Docket
  def docket_type
    Constants.AMA_DOCKETS.hearing
  end

  def ready_priority_appeals
    appeals(priority: true, ready: true)
  end

  def age_of_n_oldest_genpop_priority_appeals(num)
    HearingRequestDistributionQuery.new(
      base_relation: ready_priority_appeals.limit(num), genpop: "only_genpop"
    ).call.map(&:ready_for_distribution_at)
  end

  # Hearing cases distinguish genpop from cases tied to a judge
  def genpop_priority_count
    HearingRequestDistributionQuery.new(base_relation: ready_priority_appeals, genpop: "only_genpop").call.count
  end

  # rubocop:disable Lint/UnusedMethodArgument
  def distribute_appeals(distribution, priority: false, genpop: "any", limit: 1, style: "push")
    base_relation = appeals(priority: priority, ready: true).limit(limit)

    appeals = HearingRequestDistributionQuery.new(
      base_relation: base_relation, genpop: genpop, judge: distribution.judge
    ).call

    appeals = self.class.limit_genpop_appeals(appeals, limit) if genpop.eql? "any"

    HearingRequestCaseDistributor.new(
      appeals: appeals, genpop: genpop, distribution: distribution, priority: priority
    ).call
  end

  def self.limit_genpop_appeals(appeals_array, limit)
    # genpop 'any' returns 2 arrays of the limited base relation. This means if we only request 2 cases, appeals is a
    # 2x2 array containing 4 cases overall and we will end up distributing 4 cases rather than 2. Instead, reinstate the
    # limit here by filtering out the newest cases
    appeals_to_reject = appeals_array.flatten.sort_by(&:ready_for_distribution_at).drop(limit)
    appeals_array.map { |appeals| appeals - appeals_to_reject }
  end
end
