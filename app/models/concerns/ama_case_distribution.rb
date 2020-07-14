# frozen_string_literal: true

module AmaCaseDistribution
  extend ActiveSupport::Concern

  delegate :dockets,
           :docket_proportions,
           :priority_count,
           :direct_review_due_count,
           :pacesetting_direct_review_proportion,
           :interpolated_minimum_direct_review_proportion,
           to: :docket_coordinator

  private

  def docket_coordinator
    @docket_coordinator ||= DocketCoordinator.new
  end

  def priority_push_distribution(limit = nil)
    @appeals = []
    @rem = 0

    if limit.nil?
      # Distribute priority appeals that are tied to judges (not genpop) with no limit.
      distribute_appeals(:legacy, nil, priority: true, genpop: "not_genpop")
      distribute_appeals(:hearing, nil, priority: true, genpop: "not_genpop")
    else
      # Distribute <limit> number of cases, regardless of docket type, oldest first.
      oldest_priority_appeals_by_docket(limit).each do |docket, number_of_cases|
        distribute_appeals(docket, number_of_cases, priority: true)
      end
    end
  end

  def ama_distribution
    @appeals = []
    @rem = batch_size
    @remaining_docket_proportions = docket_proportions.clone
    @nonpriority_iterations = 0

    # Distribute priority appeals that are tied to judges (not genpop).
    distribute_appeals(:legacy, @rem, priority: true, genpop: "not_genpop")
    distribute_appeals(:hearing, @rem, priority: true, genpop: "not_genpop")

    # Distribute legacy cases tied to a judge down to the board provided limit of 30, regardless of the legacy docket
    # range
    if FeatureToggle.enabled?(:priority_acd)
      distribute_appeals(:legacy, @rem, priority: false, genpop: "not_genpop", bust_backlog: true)
    end

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
      batch_size: priority_push? ? @appeals.count : batch_size,
      total_batch_size: total_batch_size,
      priority_count: priority_count,
      direct_review_due_count: direct_review_due_count,
      legacy_hearing_backlog_count: VACOLS::CaseDocket.nonpriority_hearing_cases_for_judge_count(judge),
      legacy_proportion: docket_proportions[:legacy],
      direct_review_proportion: docket_proportions[:direct_review],
      evidence_submission_proportion: docket_proportions[:evidence_submission],
      hearing_proportion: docket_proportions[:hearing],
      pacesetting_direct_review_proportion: pacesetting_direct_review_proportion,
      interpolated_minimum_direct_review_proportion: interpolated_minimum_direct_review_proportion,
      nonpriority_iterations: @nonpriority_iterations
    }
  end

  def distribute_appeals(docket, num, priority: false, genpop: "any", range: nil, bust_backlog: false)
    return [] unless num.nil? || num > 0

    if range.nil? && !bust_backlog
      appeals = dockets[docket].distribute_appeals(self, priority: priority, genpop: genpop, limit: num)
    elsif docket == :legacy && priority == false
      appeals = dockets[docket].distribute_nonpriority_appeals(
        self, genpop: genpop, range: range, limit: num, bust_backlog: bust_backlog
      )
    else
      fail "'range' and 'bust_backlog' are only valid arguments when distributing nonpriority, legacy appeals"
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
      proportion = docket_count.to_f / nonpriority_target
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
    return {} unless num > 0

    dockets
      .flat_map { |sym, docket| docket.age_of_n_oldest_priority_appeals(num).map { |age| [age, sym] } }
      .sort_by { |a| a[0] }
      .first(num)
      .each_with_object(Hash.new(0)) { |a, counts| counts[a[1]] += 1 }
  end
end
