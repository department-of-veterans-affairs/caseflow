# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module ByDocketDateDistribution
  extend ActiveSupport::Concern
  include CaseDistribution

  private

  def priority_push_distribution(limit)
    @push_priority_target = limit
    @rem = 0
    @appeals = []
    # Distribute <limit> number of cases, regardless of docket type, oldest first.
    distribute_priority_appeals_from_all_dockets_by_age_to_limit(limit, style: "push")
    @appeals
  end

  def requested_distribution
    @appeals = []
    @rem = batch_size
    @nonpriority_iterations = 0
    @request_priority_count = priority_target

    # If we haven't yet met the priority target, distribute additional priority appeals.
    priority_rem = priority_target.clamp(0, @rem)
    distribute_priority_appeals_from_all_dockets_by_age_to_limit(priority_rem, style: "request")

    unless FeatureToggle.enabled?(:acd_disable_nonpriority_distributions, user: RequestStore.store[:current_user])
      # Distribute the oldest nonpriority appeals from any docket if we haven't distributed {batch_size} appeals
      distribute_nonpriority_appeals_from_all_dockets_by_age_to_limit(@rem) until @rem <= 0
    end
    @appeals
  end

  def distribute_priority_appeals_from_all_dockets_by_age_to_limit(limit, style: "request")
    num_oldest_priority_appeals_for_judge_by_docket(self, limit).each do |docket, number_of_appeals_to_distribute|
      collect_appeals do
        dockets[docket].distribute_appeals(self, limit: number_of_appeals_to_distribute, priority: true, style: style)
      end
    end
  end

  def distribute_nonpriority_appeals_from_all_dockets_by_age_to_limit(limit, style: "request")
    @nonpriority_iterations += 1
    num_oldest_nonpriority_appeals_for_judge_by_docket(self, limit).each do |docket, number_of_appeals_to_distribute|
      collect_appeals do
        dockets[docket].distribute_appeals(self, limit: number_of_appeals_to_distribute, priority: false, style: style)
      end
    end
  end

  def ama_statistics
    priority_counts = { count: priority_count }
    nonpriority_counts = { count: nonpriority_count }

    dockets.each_pair do |sym, docket|
      priority_counts[sym] = docket.count(priority: true, ready: true)
      nonpriority_counts[sym] = docket.count(priority: false, ready: true)
    end

    unless FeatureToggle.enabled?(:acd_disable_legacy_distributions, user: RequestStore.store[:current_user])
      priority_counts[:legacy_hearing_tied_to] = legacy_hearing_priority_count(judge)
      nonpriority_counts[:legacy_hearing_tied_to] = legacy_hearing_nonpriority_count(judge)
    end

    nonpriority_counts[:iterations] = @nonpriority_iterations

    settings = {}
    feature_toggles = [:acd_disable_legacy_distributions, :acd_disable_nonpriority_distributions]
    feature_toggles.each do |sym|
      settings[sym] = FeatureToggle.enabled?(sym, user: RequestStore.store[:current_user])
    end

    {
      batch_size: @appeals.count,
      total_batch_size: total_batch_size,
      priority_target: @push_priority_target || @request_priority_count,
      priority: priority_counts,
      nonpriority: nonpriority_counts,
      algorithm: "by_docket_date",
      settings: settings
    }
  end

  def num_oldest_priority_appeals_for_judge_by_docket(distribution, num)
    return {} unless num > 0

    dockets
      .flat_map { |sym, docket| docket.age_of_n_oldest_priority_appeals_available_to_judge(
        distribution.judge, num).map { |age| [age, sym] } }
      .sort_by { |age, _| age }
      .first(num)
      .group_by { |_, sym| sym }
      .transform_values(&:count)
  end

  def num_oldest_nonpriority_appeals_for_judge_by_docket(distribution, num)
    return {} unless num > 0

    dockets
      .flat_map { |sym, docket| docket.age_of_n_oldest_nonpriority_appeals_available_to_judge(
        distribution.judge, num).map { |age| [age, sym] } }
      .sort_by { |age, _| age }
      .first(num)
      .group_by { |_, sym| sym }
      .transform_values(&:count)
  end
end
