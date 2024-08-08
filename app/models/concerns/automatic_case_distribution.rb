# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
# This is Proportions Algorithm
module AutomaticCaseDistribution
  extend ActiveSupport::Concern
  include CaseDistribution

  private

  def priority_push_distribution(limit = nil)
    @appeals = []
    @rem = 0

    if limit.nil?
      # Distribute priority appeals that are tied to judges (not genpop) with no limit.
      args = { priority: true, genpop: "not_genpop", style: "push", limit: limit }
      @appeals += dockets[:legacy].distribute_appeals(self, args)
      @appeals += dockets[:hearing].distribute_appeals(self, args)
    else
      # Distribute <limit> number of cases, regardless of docket type, oldest first.
      distribute_limited_priority_appeals_from_all_dockets(limit, style: "push")
    end
  end

  def requested_distribution
    @appeals = []
    @rem = batch_size
    @remaining_docket_proportions = docket_proportions.clone
    @nonpriority_iterations = 0

    # Distribute legacy cases tied to a judge down to the board provided limit of 30,
    # regardless of the legacy docket range.
    if FeatureToggle.enabled?(:priority_acd, user: judge)
      collect_appeals do
        dockets[:legacy].distribute_nonpriority_appeals(
          self, style: "request", genpop: "not_genpop", limit: @rem, bust_backlog: true
        )
      end
    end

    distribute_tied_priority_appeals
    distribute_tied_nonpriority_appeals

    # If we haven't yet met the priority target, distribute additional priority appeals.
    priority_rem = (priority_target - @appeals.count(&:priority)).clamp(0, @rem)
    distribute_limited_priority_appeals_from_all_dockets(priority_rem, style: "request")

    # As we may have already distributed nonpriority legacy and hearing docket cases, we adjust the docket proportions.
    deduct_distributed_actuals_from_remaining_docket_proportions(:legacy, :hearing)

    # Distribute nonpriority appeals from any docket according to the docket proportions.
    # If a docket runs out of available appeals, we reallocate its cases to the other dockets.
    until @rem == 0 || @remaining_docket_proportions.all_zero?
      distribute_appeals_according_to_remaining_docket_proportions(style: "request")
    end

    @appeals
  end

  def distribute_tied_nonpriority_appeals
    # Legacy docket appeals that are tied to judges are only distributed when they are within the docket range.
    base_args = { genpop: "not_genpop", priority: false, style: "request" }
    collect_appeals do
      dockets[:legacy].distribute_appeals(self, base_args.merge(limit: @rem, range: legacy_docket_range))
    end
    collect_appeals do
      dockets[:hearing].distribute_appeals(self, base_args.merge(limit: @rem))
    end
  end

  def distribute_tied_priority_appeals
    base_args = { priority: true, style: "request", genpop: "not_genpop" }
    collect_appeals do
      dockets[:legacy].distribute_appeals(self, base_args.merge(limit: @rem))
    end
    collect_appeals do
      dockets[:hearing].distribute_appeals(self, base_args.merge(limit: @rem))
    end
  end

  def distribute_limited_priority_appeals_from_all_dockets(limit, style: "push")
    num_oldest_priority_appeals_by_docket(limit).each do |docket, number_of_appeals_to_distribute|
      collect_appeals do
        dockets[docket].distribute_appeals(self, limit: number_of_appeals_to_distribute, priority: true, style: style)
      end
    end
  end

  def ama_statistics
    sct_appeals_counts = @appeals.count { |appeal| appeal.try(:sct_appeal) }
    {
      statistics: {
        batch_size: @appeals.count,
        total_batch_size: total_batch_size,
        priority_count: priority_count,
        direct_review_due_count: direct_review_due_count,
        legacy_hearing_backlog_count: VACOLS::CaseDocket.nonpriority_hearing_cases_for_judge_count(judge),
        legacy_proportion: docket_proportions[:legacy],
        direct_review_proportion: docket_proportions[:direct_review],
        evidence_submission_proportion: docket_proportions[:evidence_submission],
        hearing_proportion: docket_proportions[:hearing],
        nonpriority_iterations: @nonpriority_iterations,
        sct_appeals: sct_appeals_counts
      }
    }
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

  def distribute_appeals_according_to_remaining_docket_proportions(style: "push")
    @nonpriority_iterations += 1
    @remaining_docket_proportions
      .normalize!
      .stochastic_allocation(@rem)
      .each do |docket, number_of_appeals_to_distribute|
        appeals = collect_appeals do
          dockets[docket].distribute_appeals(
            self, limit: number_of_appeals_to_distribute, priority: false, style: style, genpop: "any"
          )
        end
        @remaining_docket_proportions[docket] = 0 if appeals.count < number_of_appeals_to_distribute
      end
  end

  def docket_margin_net_of_priority
    [total_batch_size - priority_count, 0].max
  end

  def legacy_docket_range
    (docket_margin_net_of_priority * docket_proportions[:legacy]).round
  end

  def num_oldest_priority_appeals_by_docket(num)
    return {} unless num > 0

    dockets
      .flat_map { |sym, docket| docket.age_of_n_oldest_genpop_priority_appeals(num).map { |age| [age, sym] } }
      .sort_by { |age, _| age }
      .first(num)
      .group_by { |_, sym| sym }
      .transform_values(&:count)
  end
end
# rubocop:enable Metrics/ModuleLength
