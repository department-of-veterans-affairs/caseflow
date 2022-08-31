# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module AllCaseDistribution
  extend ActiveSupport::Concern

  delegate :dockets,
           :docket_proportions,
           :priority_count,
           :direct_review_due_count,
           :total_batch_size,
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

    # If we haven't yet met the priority target, distribute additional priority appeals.
    priority_rem = (priority_target - @appeals.count(&:priority)).clamp(0, @rem)
    distribute_limited_priority_appeals_from_all_dockets(priority_rem, style: "request")

    # Distribute the oldest nonpriority appeals from any docket if we haven't distributed {batch_size} appeals
    distribute_nonpriority_appeals_from_all_dockets_by_age_to_limit(@rem) until @rem == 0

    @appeals
  end

  def collect_appeals
    appeals = yield
    @rem -= appeals.count
    @appeals += appeals
    appeals
  end

  def distribute_limited_priority_appeals_from_all_dockets(limit, style: "push")
    num_oldest_priority_appeals_by_docket(limit).each do |docket, number_of_appeals_to_distribute|
      collect_appeals do
        dockets[docket].distribute_appeals(self, limit: number_of_appeals_to_distribute, priority: true, style: style)
      end
    end
  end

  def distribute_nonpriority_appeals_from_all_dockets_by_age_to_limit(limit, style: "request")
    @nonpriority_iterations += 1
    num_oldest_nonpriority_appeals_for_judge_by_docket(judge, limit).each do |docket, number_of_appeals_to_distribute|
      collect_appeals do
        dockets[docket].distribute_appeals(self, limit: number_of_appeals_to_distribute, priority: false, style: style)
      end
    end
  end

  def ama_statistics
    {
      batch_size: @appeals.count,
      total_batch_size: total_batch_size,
      priority_count: priority_count,
      direct_review_due_count: direct_review_due_count,
      legacy_hearing_backlog_count: VACOLS::CaseDocket.nonpriority_hearing_cases_for_judge_count(judge),
      legacy_proportion: docket_proportions[:legacy],
      direct_review_proportion: docket_proportions[:direct_review],
      evidence_submission_proportion: docket_proportions[:evidence_submission],
      hearing_proportion: docket_proportions[:hearing],
      nonpriority_iterations: @nonpriority_iterations
    }
  end

  def priority_target
    proportion = [priority_count.to_f / total_batch_size, 1.0].reject(&:nan?).min
    (proportion * batch_size).ceil
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

  def num_oldest_nonpriority_appeals_for_judge_by_docket(judge, num)
    return {} unless num > 0

    dockets
      .flat_map { |sym, docket| docket.age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num).map { |age| [age, sym] } }
      .sort_by { |age, _| age }
      .first(num)
      .group_by { |_, sym| sym }
      .transform_values(&:count)
  end
end
# rubocop:enable Metrics/ModuleLength
