# frozen_string_literal: true

class LegacyDocket
  include ActiveModel::Model

  # When counting the total number of appeals on the legacy docket for purposes of docket balancing, we
  # include NOD-stage appeals at a discount reflecting the likelihood that they will advance to a Form 9.
  NOD_ADJUSTMENT = 0.4

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

  def weight
    count(priority: false) + nod_count * NOD_ADJUSTMENT
  end

  def age_of_n_oldest_priority_appeals(num)
    LegacyAppeal.repository.age_of_n_oldest_priority_appeals(num)
  end

  def distribute_priority_appeals(distribution, genpop: "any", limit: 1)
    LegacyAppeal.repository.distribute_priority_appeals(distribution.judge, genpop, limit).map do |record|
      next unless existing_distribution_case_may_be_redistributed(record["bfkey"], distribution)

      dist_case = new_distributed_case(distribution, record, docket_type, genpop, true)
      save_dist_case(dist_case, record, distribution.judge)
      dist_case
    end.compact
  end

  def distribute_nonpriority_appeals(distribution, genpop: "any", range: nil, limit: 1)
    LegacyAppeal.repository.distribute_nonpriority_appeals(distribution.judge, genpop, range, limit).map do |record|
      next unless existing_distribution_case_may_be_redistributed(record["bfkey"], distribution)

      dist_case = new_distributed_case(distribution, record, docket_type, genpop, false)
      save_dist_case(dist_case, record, distribution.judge)
      dist_case
    end.compact
  end

  def distribute_appeals(distribution, priority: false, genpop: "any", limit: 1)
    if priority
      distribute_priority_appeals(distribution, genpop: genpop, limit: limit)
    else
      distribute_nonpriority_appeals(distribution, genpop: genpop, limit: limit)
    end
  end

  private

  def save_dist_case(dist_case, record, judge)
    if FeatureToggle.enabled?(:legacy_das_deprecation, user: RequestStore.store[:current_user])
      DasDeprecation::CaseDistribution.create_judge_assign_task(record, judge) { dist_case.save! }
    else
      dist_case.save!
    end
  end

  def existing_distribution_case_may_be_redistributed(case_id, distribution)
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
