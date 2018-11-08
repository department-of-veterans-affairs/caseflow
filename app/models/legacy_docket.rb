class LegacyDocket
  include ActiveModel::Model

  # When counting the total number of appeals on the legacy docket for purposes of docket balancing, we
  # include NOD-stage appeals at a discount reflecting the likelihood that they will advance to a Form 9.
  NOD_ADJUSTMENT = 0.4

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

  def distribute_priority_appeals(distribution, genpop = nil, limit = 1)
    LegacyAppeal.repository.distribute_priority_appeals(distribution.judge, genpop, limit).map do |record|
      DistributedCase.create(distribution: distribution,
                             case_id: record["bfkey"],
                             docket: "legacy",
                             priority: true,
                             ready_at: VacolsHelper.normalize_vacols_datetime(record["bfdloout"]),
                             genpop: !record["vlj"].nil?,
                             genpop_query: maybe_boolean_to_string(genpop))
    end
  end

  def distribute_nonpriority_appeals(distribution, genpop = nil, range = nil, limit = 1)
    LegacyAppeal.repository.distribute_nonpriority_appeals(distribution.judge, genpop, range, limit).map do |record|
      DistributedCase.create(distribution: distribution,
                             case_id: record["bfkey"],
                             docket: "legacy",
                             priority: false,
                             ready_at: VacolsHelper.normalize_vacols_datetime(record["bfdloout"]),
                             docket_index: record["docket_index"],
                             genpop: !record["vlj"].nil?,
                             genpop_query: maybe_boolean_to_string(genpop))
    end
  end

  private

  def counts_by_priority_and_readiness
    @counts_by_priority_and_readiness ||= LegacyAppeal.repository.docket_counts_by_priority_and_readiness
  end

  def nod_count
    @nod_count ||= LegacyAppeal.repository.nod_count
  end

  def maybe_boolean_to_string(bool)
    case bool
    when nil?
      "any"
    when true
      "yes"
    when false
      "no"
    end
  end
end
