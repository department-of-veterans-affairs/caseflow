# rubocop:disable Metrics/ModuleLength
module AmaCaseDistribution
  extend ActiveSupport::Concern

  private

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def ama_distribution
    rem = batch_size
    priority_target = target_number_of_priority_appeals
    remaining_docket_proportions = docket_proportions

    priority_legacy_hearing_appeals =
      dockets[:legacy].distribute_appeals(self, priority: true, genpop: "not_genpop", limit: rem)
    rem -= priority_legacy_hearing_appeals.count

    priority_hearing_appeals =
      dockets[:hearing].distribute_appeals(self, priority: true, genpop: "not_genpop", limit: rem)
    rem -= priority_hearing_appeals.count

    nonpriority_legacy_hearing_appeals =
      dockets[:legacy].distribute_nonpriority_appeals(self,
                                                      genpop: "not_genpop",
                                                      range: legacy_nonpriority_docket_range,
                                                      limit: rem)
    rem -= nonpriority_legacy_hearing_appeals.count

    nonpriority_hearing_appeals =
      dockets[:hearing].distribute_appeals(self, priority: false, genpop: "not_genpop", limit: rem)
    rem -= nonpriority_hearing_appeals.count

    priority_distributed_count = priority_legacy_hearing_appeals.count + priority_hearing_appeals.count
    hearing_distributed_count = priority_hearing_appeals.count + nonpriority_hearing_appeals.count
    legacy_distributed_count = priority_legacy_hearing_appeals.count + nonpriority_legacy_hearing_appeals.count

    if priority_distributed_count < priority_target
      priority_rem = [priority_target - priority_distributed_count, rem].min
      other_priority_n_by_docket = dockets_with_oldest_n_priority_appeals(priority_rem)

      other_priority_appeals_by_docket = {}
      other_priority_n_by_docket.each do |docket, n|
        other_priority_appeals_by_docket[docket] =
          dockets[docket].distribute_appeals(self, priority: true, limit: n)
      end

      other_priority_appeals = other_priority_appeals_by_docket.values.flatten
      rem -= other_priority_appeals.count

      priority_distributed_count += other_priority_appeals.count
      hearing_distributed_count += (other_priority_appeals_by_docket.try(:hearing).try(:count) || 0)
      legacy_distributed_count += (other_priority_appeals_by_docket.try(:legacy).try(:count) || 0)
    end

    nonpriority_target = batch_size - priority_distributed_count

    if hearing_distributed_count > docket_proportions[:hearing] * nonpriority_target
      remaining_docket_proportions = remaining_docket_proportions.except(:hearing)
    end

    if legacy_distributed_count > docket_proportions[:legacy] * nonpriority_target
      remaining_docket_proportions = remaining_docket_proportions.except(:legacy)
    end

    other_nonpriority_appeals = []

    until rem == 0 || remaining_docket_proportions.empty?
      remaining_docket_proportions = normalize_proportions(remaining_docket_proportions)
      docket_targets = stochastic_allocation(rem, remaining_docket_proportions)

      docket_targets.each do |docket, n|
        cases = dockets[docket].distribute_appeals(self, priority: false, limit: n)
        other_nonpriority_appeals += cases
        rem -= cases.count

        if cases.count < n
          remaining_docket_proportions = remaining_docket_proportions.except(docket)
        end
      end
    end

    [
      *priority_legacy_hearing_appeals, *priority_hearing_appeals,
      *nonpriority_legacy_hearing_appeals, *nonpriority_hearing_appeals,
      *other_priority_appeals, *other_nonpriority_appeals
    ]
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize

  # CMGTODO
  def ama_statistics; end

  def dockets
    @dockets ||= {
      legacy: LegacyDocket.new,
      direct_review: AmaDirectReviewDocket.new,
      evidence_submission: AmaEvidenceSubmissionDocket.new,
      hearing: AmaHearingDocket.new
    }
  end

  def priority_count
    @priority_count ||= dockets
      .values
      .map { |docket| docket.count(priority: true, ready: true) }
      .reduce(0, :+)
  end

  def target_number_of_priority_appeals
    proportion = [priority_count.to_f / total_batch_size, 1.0].min
    (proportion * batch_size).ceil
  end

  def legacy_nonpriority_docket_range
    [(total_batch_size - priority_count) * docket_proportions[:legacy], 0].max.round
  end

  def dockets_with_oldest_n_priority_appeals(n)
    dockets.map { |sym, docket| docket.age_of_n_oldest_priority_appeals(n).map { |age| [age, sym] } }
      .flatten
      .sort_by { |a| a[0] }
      .first(n)
      .each_with_object(Hash.new(0)) { |a, counts| counts[a[1]] += 1 }
  end

  # CMGTODO
  def docket_proportions
    @docket_proportions ||= normalize_proportions(dockets.map(&:weight))
  end

  def normalize_proportions(proportions)
    total = proportions.values.reduce(0, :+)
    proportions.transform_values { |p| p * (1.0 / total) }
  end

  def stochastic_allocation(n, proportions)
    result = proportions.transform_values { |p| (n * p).floor }
    rem = n - result.values.reduce(0, :+)

    return result if rem == 0

    iterations = rem

    catch :complete do
      proportions.each_with_index do |(docket, p), i|
        if i == proportions.count - 1
          result[docket] += rem
          throw :complete
        end

        probability = (n * p).modulo(1) / iterations

        iterations.times do
          next unless probability > rand

          result[docket] += 1
          rem -= 1

          throw :complete if rem == 0
        end
      end
    end

    result
  end
end
# rubocop:enable Metrics/ModuleLength
