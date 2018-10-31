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

  def oldest_priority_appeal_ready_date
    LegacyAppeal.repository.oldest_priority_appeal_ready_date
  end

  def distribute_priority_appeals(judge, genpop = nil, limit = 1); end

  def distribute_non_priority_appeals(judge, genpop = nil, range = nil, limit = 1); end

  private

  def counts_by_priority_and_readiness
    @counts_by_priority_and_readiness ||= LegacyAppeal.repository.counts_by_priority_and_readiness
  end

  def nod_count
    @nod_count ||= LegacyAppeal.repository.nod_count
  end
end
