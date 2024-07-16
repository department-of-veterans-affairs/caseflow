# frozen_string_literal: true

class LegacyAojDocket < LegacyDocket
  def docket_type
    self.class.docket_type
  end

  def ready_to_distribute_appeals
    LegacyAppeal.aoj_appeal_repository.ready_to_distribute_appeals
  end

  def counts_by_priority_and_readiness
    @counts_by_priority_and_readiness ||= LegacyAppeal.aoj_appeal_repository.docket_counts_by_priority_and_readiness
  end

  def genpop_priority_count
    LegacyAppeal.aoj_appeal_repository.genpop_priority_count
  end

  def not_genpop_priority_count
    LegacyAppeal.aoj_appeal_repository.not_genpop_priority_count
  end

  def ready_priority_appeal_ids
    LegacyAppeal.aoj_appeal_repository.priority_ready_appeal_vacols_ids
  end

  def age_of_oldest_priority_appeal
    @age_of_oldest_priority_appeal ||=
      if use_by_docket_date?
        LegacyAppeal.aoj_appeal_repository.age_of_oldest_priority_appeal_by_docket_date
      else
        LegacyAppeal.aoj_appeal_repository.age_of_oldest_priority_appeal
      end
  end

  def age_of_n_oldest_priority_appeals_available_to_judge(judge, num)
    LegacyAppeal.aoj_appeal_repository.age_of_n_oldest_priority_appeals_available_to_judge(judge, num)
  end

  def age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num)
    LegacyAppeal.aoj_appeal_repository.age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num)
  end

  def distribute_priority_appeals(distribution, style: "push", genpop: "any", limit: 1)
    return [] unless should_distribute?(distribution, style: style, genpop: genpop)

    LegacyAppeal.aoj_appeal_repository.distribute_priority_appeals(distribution.judge, genpop, limit).map do |record|
      next unless existing_distribution_case_may_be_redistributed?(record["bfkey"], distribution)

      dist_case = new_distributed_case(distribution, record, docket_type, genpop, true)
      save_dist_case(dist_case)
      dist_case
    end.compact
  end

  def distribute_nonpriority_appeals(distribution,
                                     style: "push",
                                     genpop: "any",
                                     range: nil,
                                     limit: 1,
                                     bust_backlog: false)
    return [] unless should_distribute?(distribution, style: style, genpop: genpop)

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
end
