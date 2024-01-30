# frozen_string_literal: true

class HearingRequestDocket < Docket
  def docket_type
    Constants.AMA_DOCKETS.hearing
  end

  def ready_priority_appeals
    appeals(priority: true, ready: true)
  end

  def ready_nonpriority_appeals
    appeals(priority: false, ready: true)
  end

  def age_of_n_oldest_genpop_priority_appeals(num)
    hearing_distribution_query(
      base_relation: ready_priority_appeals.limit(num), genpop: "only_genpop"
    ).call.map(&:ready_for_distribution_at)
  end

  # this method needs to have the same name as the method in legacy_docket.rb for by_docket_date_distribution,
  # but the judge that is passed in isn't relevant here
  def age_of_n_oldest_nonpriority_appeals_available_to_judge(_judge, num)
    hearing_distribution_query(
      base_relation: ready_nonpriority_appeals.limit(num), genpop: "only_genpop"
    ).call.map(&:receipt_date)
  end

  # Hearing cases distinguish genpop from cases tied to a judge
  # Returns number of ready priority appeals that are not tied to a judge
  def genpop_priority_count
    hearing_distribution_query(base_relation: ready_priority_appeals, genpop: "only_genpop").call.count
  end

  def age_of_n_oldest_priority_appeals_available_to_judge(_judge, num)
    hearing_distribution_query(
      base_relation: ready_priority_appeals.limit(num), genpop: "only_genpop"
    ).call.map(&:receipt_date)
  end

  # rubocop:disable Lint/UnusedMethodArgument
  def distribute_appeals(distribution, priority: false, genpop: "any", limit: 1, style: "push")
    base_relation = appeals(priority: priority, ready: true).limit(limit)

    # setting genpop to "only_genpop" behind feature toggle as this module only processes AMA
    genpop = "only_genpop" if use_by_docket_date?

    appeals = hearing_distribution_query(base_relation: base_relation, genpop: genpop, judge: distribution.judge).call

    appeals = self.class.limit_genpop_appeals(appeals, limit) if genpop.eql? "any"

    appeals = self.class.limit_only_genpop_appeals(appeals, limit) if genpop.eql?("only_genpop") && limit

    HearingRequestCaseDistributor.new(
      appeals: appeals, genpop: genpop, distribution: distribution, priority: priority
    ).call
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # Common creation of the query object so can pass in feature toggle checks
  def hearing_distribution_query(base_relation:, genpop:, judge: nil)
    HearingRequestDistributionQuery.new(
      base_relation: base_relation, genpop: genpop, judge: judge,
      use_by_docket_date: use_by_docket_date?
    )
  end

  def self.limit_genpop_appeals(appeals_array, limit)
    # genpop 'any' returns 2 arrays of the limited base relation. This means if we only request 2 cases, appeals is a
    # 2x2 array containing 4 cases overall and we will end up distributing 4 cases rather than 2. Instead, reinstate the
    # limit here by filtering out the newest cases
    appeals_to_reject = appeals_array.flatten.sort_by(&:ready_for_distribution_at).drop(limit)
    appeals_array.map { |appeals| appeals - appeals_to_reject }
  end

  def self.limit_only_genpop_appeals(appeals_array, limit)
    # genpop 'only_genpop' returns 2 arrays of the limited base relation. This means if we only request 2 cases,
    # appeals is a 2x2 array containing 4 cases overall and we will end up distributing 4 cases rather than 2.
    # Instead, reinstate the limit here by filtering out the newest cases
    appeals_array.flatten.sort_by(&:receipt_date).first(limit)
  end
end
