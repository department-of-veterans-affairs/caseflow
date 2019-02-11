# rubocop:disable Metrics/ModuleLength
module AmaCaseDistribution
  extend ActiveSupport::Concern

  # MINIMUM_LEGACY_PROPORTION + MAXIMUM_DIRECT_REVIEW_PROPORTION cannot exceed 1.
  MINIMUM_LEGACY_PROPORTION = 0.1
  MAXIMUM_DIRECT_REVIEW_PROPORTION = 0.8

  # A lever controlling how many direct review docket appeals are distributed before the time goal is reached.
  # A lower number will distribute fewer appeals, accelerating faster toward the time goal.
  INTERPOLATED_DIRECT_REVIEW_PROPORTION_ADJUSTMENT = 0.67

  private

  def ama_distribution
    @appeals = []
    @rem = batch_size
    @remaining_docket_proportions = docket_proportions.clone
    @nonpriority_iterations = 0

    # Count the number of priority appeals available before we distribute anything.
    priority_count

    # Distribute priority appeals that are tied to judges (not genpop).
    distribute_appeals(:legacy, @rem, priority: true, genpop: "not_genpop")
    distribute_appeals(:hearing, @rem, priority: true, genpop: "not_genpop")

    # Distribute nonpriority appeals that are tied to judges.
    # Legacy docket appeals that are tied to judges are only distributed when they are within the docket range.
    distribute_appeals(:legacy, @rem, priority: false, genpop: "not_genpop", range: legacy_docket_range)
    distribute_appeals(:hearing, @rem, priority: false, genpop: "not_genpop")

    # If we haven't yet met the priority target, distribute additional priority appeals.
    priority_rem = (priority_target - @appeals.count(&:priority)).clamp(0, @rem)
    oldest_priority_appeals_by_docket(priority_rem).each do |docket, n|
      distribute_appeals(docket, n, priority: true)
    end

    # As we may have already distributed nonpriority legacy and hearing docket cases, we adjust the docket proportions.
    deduct_distributed_actuals_from_remaining_docket_proportions(:legacy, :hearing)

    # Distribute nonpriority appeals from any docket according to the docket proportions.
    # If a docket runs out of available appeals, we reallocate its cases to the other dockets.
    until @rem == 0 || @remaining_docket_proportions.all_zero?
      distribute_appeals_according_to_remaining_docket_proportions
      @nonpriority_iterations += 1
    end

    @appeals
  end

  def ama_statistics
    {
      batch_size: batch_size,
      total_batch_size: total_batch_size,
      priority_count: priority_count,
      direct_review_due_count: direct_review_due_count,
      legacy_proportion: docket_proportions[:legacy],
      direct_review_proportion: docket_proportions[:direct_review],
      evidence_submission_proportion: docket_proportions[:evidence_submission],
      hearing_proportion: docket_proportions[:hearing],
      pacesetting_direct_review_proportion: pacesetting_direct_review_proportion,
      interpolated_minimum_direct_review_proportion: interpolated_minimum_direct_review_proportion,
      nonpriority_iterations: @nonpriority_iterations
    }
  end

  def distribute_appeals(docket, num, priority: false, genpop: "any", range: nil)
    return [] unless num > 0

    if range.nil?
      appeals = dockets[docket].distribute_appeals(self, priority: priority, genpop: genpop, limit: num)
    elsif docket == :legacy && priority == false
      return [] unless range > 0

      appeals = dockets[:legacy].distribute_nonpriority_appeals(self, genpop: genpop, range: range, limit: num)
    else
      return
    end

    @appeals += appeals
    @rem -= appeals.count

    appeals
  end

  def deduct_distributed_actuals_from_remaining_docket_proportions(*dockets)
    nonpriority_target = batch_size - @appeals.count(&:priority)

    return if nonpriority_target == 0

    dockets.each do |docket|
      docket_count = @appeals.count { |appeal| appeal.docket == docket.to_s && !appeal.priority }
      proportion = docket_count / nonpriority_target
      @remaining_docket_proportions[docket] = [@remaining_docket_proportions[docket] - proportion, 0].max
    end
  end

  def distribute_appeals_according_to_remaining_docket_proportions
    @remaining_docket_proportions
      .normalize!
      .stochastic_allocation(@rem)
      .each do |docket, n|
        appeals = distribute_appeals(docket, n, priority: false)
        @remaining_docket_proportions[docket] = 0 if appeals.count < n
      end
  end

  def dockets
    @dockets ||= {
      legacy: LegacyDocket.new,
      direct_review: DirectReviewDocket.new,
      evidence_submission: EvidenceSubmissionDocket.new,
      hearing: HearingRequestDocket.new
    }
  end

  def priority_count
    @priority_count ||= dockets
      .values
      .map { |docket| docket.count(priority: true, ready: true) }
      .reduce(0, :+)
  end

  def priority_target
    proportion = [priority_count.to_f / total_batch_size, 1].min
    (proportion * batch_size).ceil
  end

  def docket_margin_net_of_priority
    [total_batch_size - priority_count, 0].max
  end

  def legacy_docket_range
    (docket_margin_net_of_priority * docket_proportions[:legacy]).round
  end

  def oldest_priority_appeals_by_docket(num)
    return {} unless n > 0

    dockets
      .map { |sym, docket| docket.age_of_n_oldest_priority_appeals(n).map { |age| [age, sym] } }
      .flatten
      .sort_by { |a| a[0] }
      .first(num)
      .each_with_object(Hash.new(0)) { |a, counts| counts[a[1]] += 1 }
  end

  def docket_proportions
    return @docket_proportions if @docket_proportions

    # We distribute appeals proportional to each docket's "weight," basically the number of pending appeals.
    # LegacyDocket makes adjustments to the weight to account for pre-Form 9 appeals.
    @docket_proportions = dockets
      .transform_values(&:weight)
      .extend(ProportionHash)

    # Prevent divide by zero errors if 100% of the docket margin is priority.
    return @docket_proportions.normalize! if docket_margin_net_of_priority == 0

    # Unlike the other dockets, the direct review docket observes a time goal.
    # We distribute appeals from the docket sufficient to meet the goal, instead of proportionally.
    # When there are no or few "due" direct review appeals, we instead calculate a curve out.
    direct_review_proportion = (direct_review_due_count / docket_margin_net_of_priority)
      .clamp(interpolated_minimum_direct_review_proportion, MAXIMUM_DIRECT_REVIEW_PROPORTION)

    @docket_proportions.add_fixed_proportions!(direct_review: direct_review_proportion)

    # The legacy docket proportion is subject to a minimum, provided we have at least that many legacy appeals.
    if @docket_proportions[:legacy] < MINIMUM_LEGACY_PROPORTION
      legacy_proportion = [
        MINIMUM_LEGACY_PROPORTION,
        dockets[:legacy].count(priority: false, ready: true).to_f / docket_margin_net_of_priority
      ].min

      @docket_proportions.add_fixed_proportions!(
        legacy: legacy_proportion,
        direct_review: direct_review_proportion
      )
    end

    @docket_proportions
  end

  def direct_review_due_count
    @direct_review_due_count ||= dockets[:direct_review].due_count
  end

  def interpolated_minimum_direct_review_proportion
    return @interpolated_minimum_direct_review_proportion if @interpolated_minimum_direct_review_proportion

    t = 1 - (dockets[:direct_review].time_until_due_of_oldest_appeal /
             dockets[:direct_review].time_until_due_of_new_appeal)

    @interpolated_minimum_direct_review_proportion =
      (pacesetting_direct_review_proportion * t * INTERPOLATED_DIRECT_REVIEW_PROPORTION_ADJUSTMENT)
        .clamp(0, MAXIMUM_DIRECT_REVIEW_PROPORTION)
  end

  def pacesetting_direct_review_proportion
    return @pacesetting_direct_review_proportion if @pacesetting_direct_review_proportion

    receipts_per_year = dockets[:direct_review].nonpriority_receipts_per_year
    decisions_per_year = Appeal.nonpriority_decisions_per_year + LegacyAppeal.nonpriority_decisions_per_year

    @pacesetting_direct_review_proportion = receipts_per_year / decisions_per_year
  end

  module ProportionHash
    def normalize!(to: 1.0)
      total = values.reduce(0, :+)
      transform_values! { |proportion| proportion * (to / total) }
    end

    def add_fixed_proportions!(fixed)
      except!(*fixed.keys)
        .normalize!(to: 1.0 - fixed.values.reduce(0, :+))
        .merge!(fixed)
    end

    def stochastic_allocation(num)
      result = transform_values { |proportion| (num * proportion).floor }
      rem = num - result.values.reduce(0, :+)

      return result if rem == 0

      cumulative_probabilities = inject({}) do |hash, (key, proportion)|
        probability = (num * proportion).modulo(1) / rem
        hash[key] = (hash.values.last || 0) + probability
        hash
      end

      rem.times do
        random = rand
        pick = cumulative_probabilities.find { |_, cumprob| cumprob > random }
        key = pick ? pick[0] : cumulative_probabilities.keys.last
        result[key] += 1
      end

      result
    end

    def all_zero?
      all? { |_, proportion| proportion == 0 }
    end
  end
end
# rubocop:enable Metrics/ModuleLength
