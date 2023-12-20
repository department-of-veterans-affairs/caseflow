# frozen_string_literal: true

class LegacyDocket < Docket
  def docket_type
    "legacy"
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def count(priority: nil, ready: nil)
    counts_by_priority_and_readiness.inject(0) do |sum, row|
      next sum unless (priority.nil? || (priority ? 1 : 0) == row["priority"]) &&
                      (ready.nil? || (ready ? 1 : 0) == row["ready"])

      sum + row["n"]
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def genpop_priority_count
    LegacyAppeal.repository.genpop_priority_count
  end

  def not_genpop_priority_count
    LegacyAppeal.repository.not_genpop_priority_count
  end

  def weight
    count(priority: false) + nod_count * Constants.DISTRIBUTION.nod_adjustment
  end

  def ready_priority_appeal_ids
    LegacyAppeal.repository.priority_ready_appeal_vacols_ids
  end

  def oldest_priority_appeal_days_waiting
    return 0 if age_of_oldest_priority_appeal.nil?

    (Time.zone.now.to_date - age_of_oldest_priority_appeal.to_date).to_i
  end

  def age_of_oldest_priority_appeal
    if use_by_docket_date?
      @age_of_oldest_priority_appeal ||= LegacyAppeal.repository.age_of_oldest_priority_appeal_by_docket_date
    else
      @age_of_oldest_priority_appeal ||= LegacyAppeal.repository.age_of_oldest_priority_appeal
    end
  end

  def age_of_n_oldest_genpop_priority_appeals(num)
    LegacyAppeal.repository.age_of_n_oldest_genpop_priority_appeals(num)
  end

  def age_of_n_oldest_priority_appeals_available_to_judge(judge, num)
    LegacyAppeal.repository.age_of_n_oldest_priority_appeals_available_to_judge(judge, num)
  end

  def age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num)
    LegacyAppeal.repository.age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num)
  end

  def should_distribute?(distribution, style: "push", genpop: "any")
    genpop == "not_genpop" || # always distribute tied cases
      (style == "push" && !JudgeTeam.for_judge(distribution.judge)&.ama_only_push) ||
      (style == "request" && !JudgeTeam.for_judge(distribution.judge)&.ama_only_request)
  end

  # rubocop:disable Metrics/ParameterLists
  def distribute_appeals(distribution, style: "push", priority: false, genpop: "any", limit: 1, range: nil)
    return [] unless should_distribute?(distribution, style: style, genpop: genpop)

    if priority
      distribute_priority_appeals(distribution, style: style, genpop: genpop, limit: limit)
    else
      distribute_nonpriority_appeals(distribution, style: style, genpop: genpop, limit: limit, range: range)
    end
  end
  # rubocop:enable Metrics/ParameterLists

  def distribute_priority_appeals(distribution, style: "push", genpop: "any", limit: 1)
    return [] unless should_distribute?(distribution, style: style, genpop: genpop)

    LegacyAppeal.repository.distribute_priority_appeals(distribution.judge, genpop, limit).map do |record|
      next unless existing_distribution_case_may_be_redistributed?(record["bfkey"], distribution)

      dist_case = new_distributed_case(distribution, record, docket_type, genpop, true)
      save_dist_case(dist_case)
      dist_case
    end.compact
  end

  # rubocop:disable Metrics/ParameterLists
  def distribute_nonpriority_appeals(distribution,
                                     style: "push",
                                     genpop: "any",
                                     range: nil,
                                     limit: 1,
                                     bust_backlog: false)
    return [] unless should_distribute?(distribution, style: style, genpop: genpop)

    return [] if !range.nil? && range <= 0

    LegacyAppeal.repository.distribute_nonpriority_appeals(
      distribution.judge, genpop, range, limit, bust_backlog
    ).map do |record|
      next unless existing_distribution_case_may_be_redistributed?(record["bfkey"], distribution)

      dist_case = new_distributed_case(distribution, record, docket_type, genpop, false)
      save_dist_case(dist_case)
      dist_case
    end.compact
  end
  # rubocop:enable Metrics/ParameterLists

  private

  def save_dist_case(dist_case)
    if FeatureToggle.enabled?(:legacy_das_deprecation, user: RequestStore.store[:current_user])
      DasDeprecation::CaseDistribution.create_judge_assign_task(record, judge) { dist_case.save! }
    else
      dist_case.save!
    end
  end

  def existing_distribution_case_may_be_redistributed?(case_id, distribution)
    return true unless existing_distributed_case(case_id)

    redistributed_case = RedistributedCase.new(case_id: case_id, new_distribution: distribution)
    redistributed_case.allow!
  end

  def new_distributed_case(distribution, record, docket_type, genpop, priority)
    DistributedCase.new(
      distribution: distribution,
      case_id: record["bfkey"],
      docket: docket_type,
      priority: priority,
      ready_at: VacolsHelper.normalize_vacols_datetime(record["bfdloout"]),
      docket_index: record["docket_index"],
      genpop: record["vlj"].nil?,
      genpop_query: genpop
    )
  end

  def existing_distributed_case(case_id)
    DistributedCase.find_by(case_id: case_id)
  end

  def counts_by_priority_and_readiness
    @counts_by_priority_and_readiness ||= LegacyAppeal.repository.docket_counts_by_priority_and_readiness
  end

  def nod_count
    @nod_count ||= LegacyAppeal.repository.nod_count
  end
end
