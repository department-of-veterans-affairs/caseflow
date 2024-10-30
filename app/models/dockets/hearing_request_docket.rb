# frozen_string_literal: true

class HearingRequestDocket < Docket
  def docket_type
    Constants.AMA_DOCKETS.hearing
  end

  def age_of_n_oldest_genpop_priority_appeals(num)
    hearing_distribution_query(
      base_relation: ready_priority_nonpriority_appeals(priority: true, ready: true).limit(num), genpop: "only_genpop"
    ).call.map(&:ready_for_distribution_at)
  end

  # this method needs to have the same name as the method in legacy_docket.rb for by_docket_date_distribution,
  # but the judge that is passed in isn't relevant here
  def age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num)
    hearing_distribution_query(
      base_relation: ready_priority_nonpriority_appeals(
        priority: false,
        ready: true,
        judge: judge
      ).limit(num), genpop: "only_genpop", judge: judge
    ).call.map(&:receipt_date)
  end

  # Hearing cases distinguish genpop from cases tied to a judge
  # Returns number of ready priority appeals that are not tied to a judge
  def genpop_priority_count
    hearing_distribution_query(
      base_relation: ready_priority_nonpriority_appeals(
        priority: true,
        ready: true
      ), genpop: "only_genpop"
    ).call.count
  end

  def age_of_n_oldest_priority_appeals_available_to_judge(judge, num)
    hearing_distribution_query(
      base_relation: ready_priority_nonpriority_appeals(
        priority: true,
        ready: true,
        judge: judge
      ).limit(num), genpop: "only_genpop", judge: judge
    ).call.flatten.map(&:receipt_date)
  end

  # rubocop:disable Lint/UnusedMethodArgument
  def distribute_appeals(distribution, priority: false, genpop: "any", limit: 1, style: "push")
    # setting genpop to "only_genpop" behind feature toggle as this module only processes AMA.
    genpop = "only_genpop" if use_by_docket_date?

    query_args = { priority: priority, genpop: genpop, ready: true, judge: distribution.judge }
    base_relation = ready_priority_nonpriority_appeals(query_args).limit(limit)

    sct_appeals = extract_sct_appeals(query_args, limit)

    unless sct_appeals.empty?
      base_relation = base_relation.where("appeals.id NOT IN (?)", sct_appeals.pluck(:id))
    end

    appeals = hearing_distribution_query(base_relation: base_relation, genpop: genpop, judge: distribution.judge).call

    appeals = self.class.limit_genpop_appeals(appeals, limit) if genpop.eql? "any"

    appeals = self.class.limit_only_genpop_appeals(appeals, limit) if genpop.eql?("only_genpop") && limit

    HearingRequestCaseDistributor.new(
      appeals: appeals, genpop: genpop, distribution: distribution, priority: priority, sct_appeals: sct_appeals
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
    # 2x2 array containing 4 cases overall and we will end up distributing 4 cases rather than 2.
    # Instead, reinstate the limit here by filtering out the newest cases
    appeals_to_reject = appeals_array.flatten.sort_by(&:ready_for_distribution_at).drop(limit)
    appeals_array.map { |appeals| appeals - appeals_to_reject }
  end

  def extract_sct_appeals(query_args, limit)
    if sct_distribution_enabled?
      _, sct_appeals = create_sct_appeals(query_args, limit)
      sct_appeals
    else
      []
    end
  end

  def self.limit_only_genpop_appeals(appeals_array, limit)
    if FeatureToggle.enabled?(:acd_exclude_from_affinity)
      appeals_array.flatten.sort_by(&:receipt_date).first(limit)
    else
      appeals_array.sort_by(&:receipt_date).first(limit)
    end

    # genpop 'only_genpop' returns 2 arrays of the limited base relation. This means if we only request 2 cases,
    # appeals is a 2x2 array containing 4 cases overall and we will end up distributing 4 cases rather than 2.
    # Instead, reinstate the limit here by filtering out the newest cases
  end

  # used for distribution_stats
  # :reek:ControlParameter
  # :reek:FeatureEnvy
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Style/ConditionalAssignment\
  def affinity_date_count(in_window, priority)
    scope = docket_appeals
      .joins(:hearings)
      .genpop_base_query
      .ready_for_distribution
      .with_held_hearings

    non_aod_lever = CaseDistributionLever.ama_hearing_case_affinity_days
    aod_lever = CaseDistributionLever.ama_hearing_case_aod_affinity_days

    return scope.none if priority && aod_lever&.is_a?(String)
    return scope.none if !priority && non_aod_lever&.is_a?(String)

    if in_window
      scope = priority ? affinitized_scope(scope, aod_lever) : affinitized_scope(scope, non_aod_lever)
    else
      scope = priority ? expired_scope(scope, aod_lever) : expired_scope(scope, non_aod_lever)
    end

    priority ? scoped_for_priority(scope).ids.size : scope.nonpriority.ids.size
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Style/ConditionalAssignment

  def affinitized_scope(scope, lever)
    lever.is_a?(Integer) ? scope.affinitized_ama_affinity_cases(lever) : scope
  end

  def expired_scope(scope, lever)
    lever.is_a?(Integer) ? scope.expired_ama_affinity_cases(lever) : scope
  end
end
