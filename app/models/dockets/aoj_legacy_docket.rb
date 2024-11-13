# frozen_string_literal: true

class AojLegacyDocket < LegacyDocket
  def ready_to_distribute_appeals
    LegacyAppeal.aoj_appeal_repository.ready_to_distribute_appeals
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
    LegacyAppeal.aoj_appeal_repository.genpop_priority_count
  end

  def not_genpop_priority_count
    LegacyAppeal.aoj_appeal_repository.not_genpop_priority_count
  end

  def ready_priority_appeal_ids
    LegacyAppeal.aoj_appeal_repository.priority_ready_appeal_vacols_ids
  end

  def oldest_priority_appeal_days_waiting
    return 0 if age_of_oldest_priority_appeal.nil?

    (Time.zone.now.to_date - age_of_oldest_priority_appeal.to_date).to_i
  end

  def age_of_oldest_priority_appeal
    @age_of_oldest_priority_appeal ||=
      if use_by_docket_date?
        LegacyAppeal.aoj_appeal_repository.age_of_oldest_priority_appeal_by_docket_date
      else
        LegacyAppeal.aoj_appeal_repository.age_of_oldest_priority_appeal
      end
  end

  # rubocop:disable Lint/UnusedMethodArgument
  def age_of_n_oldest_priority_appeals_available_to_judge(judge, num, genpop: nil)
    return [] unless ready_priority_nonpriority_legacy_appeals(priority: true)

    LegacyAppeal.aoj_appeal_repository.age_of_n_oldest_priority_appeals_available_to_judge(judge, num)
  end
  # rubocop:enable Lint/UnusedMethodArgument

  def age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num)
    return [] unless ready_priority_nonpriority_legacy_appeals(priority: false)

    LegacyAppeal.aoj_appeal_repository.age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num)
  end

  def distribute_priority_appeals(distribution, style: "push", genpop: "any", limit: 1)
    return [] unless should_distribute?(distribution, style: style, genpop: genpop)
    return [] unless ready_priority_nonpriority_legacy_appeals(priority: true)

    LegacyAppeal.aoj_appeal_repository.distribute_priority_appeals(distribution.judge, genpop, limit).map do |record|
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
    return [] unless ready_priority_nonpriority_legacy_appeals(priority: false)
    return [] if !range.nil? && range <= 0

    LegacyAppeal.aoj_appeal_repository.distribute_nonpriority_appeals(
      distribution.judge, genpop, range, limit, bust_backlog
    ).map do |record|
      next unless existing_distribution_case_may_be_redistributed?(record["bfkey"], distribution)

      dist_case = new_distributed_case(distribution, record, docket_type, genpop, false)
      save_dist_case(dist_case)
      dist_case
    end.compact
  end
  # rubocop:enable Metrics/ParameterLists

  def priority_appeals_affinity_date_count(in_window)
    LegacyAppeal.aoj_appeal_repository.priority_appeals_affinity_date_count(in_window).size
  end

  def non_priority_appeals_affinity_date_count(in_window)
    LegacyAppeal.aoj_appeal_repository.non_priority_appeals_affinity_date_count(in_window).size
  end

  def appeals_tied_to_non_ssc_avljs
    LegacyAppeal.aoj_appeal_repository.appeals_tied_to_non_ssc_avljs
  end

  private

  def counts_by_priority_and_readiness
    @counts_by_priority_and_readiness ||= LegacyAppeal.aoj_appeal_repository.docket_counts_by_priority_and_readiness
  end
end
