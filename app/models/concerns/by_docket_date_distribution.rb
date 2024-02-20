# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module ByDocketDateDistribution
  extend ActiveSupport::Concern
  include CaseDistribution

  private

  # Allow for more than one attempt at distributing nonpriority appeals. allowing a large number of retries
  # will cause VACOLS timeouts to occur because the entire distribution event is wrapped in a transaction and won't
  # commit those rows until all nonpriority iteration attempts are complete. some of the queries to retrieve appeals
  # can take several seconds which makes the entire process take several minutes if we allow too many iterations
  MAX_NONPRIORITY_ITERATIONS = 2

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
      # @nonpriority_iterations guards against an infinite loop if not enough cases are ready to distribute
      until @rem <= 0 || @nonpriority_iterations >= MAX_NONPRIORITY_ITERATIONS
        distribute_nonpriority_appeals_from_all_dockets_by_age_to_limit(@rem)
      end
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

  # rubocop:disable Metrics/MethodLength
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
      distributed_cases_tied_to_ineligible_judges: {
        ama: ama_distributed_cases_tied_to_ineligible_judges,
        legacy: distributed_cases_tied_to_ineligible_judges
      },
      algorithm: "by_docket_date",
      settings: settings
    }
  rescue StandardError => error
    # There always needs to be a batch_size value for a completed distribution, else the priority push job will error
    {
      batch_size: @appeals.count,
      message: "Distribution successful, but there was an error generating statistics: \
               #{error.class}: #{error.message}, #{error.backtrace.first}"
    }
  end
  # rubocop:enable Metrics/MethodLength

  def ama_distributed_cases_tied_to_ineligible_judges
    @appeals.filter_map do |appeal|
      appeal[:case_id] if HearingRequestDistributionQuery.ineligible_judges_id_cache
        &.include?(hearing_judge_id(appeal))
    end
  end

  def distributed_cases_tied_to_ineligible_judges
    @appeals.filter_map do |appeal|
      appeal[:case_id] if Rails.cache.fetch("case_distribution_ineligible_judges")&.pluck(:sattyid)&.reject(&:blank?)
        &.include?(hearing_judge_id(appeal))
    end
  end

  def hearing_judge_id(appeal)
    if appeal[:docket] == "legacy"
      user_id = LegacyAppeal.find_by(vacols_id: appeal[:case_id])
        &.hearings&.select(&:held?)&.max_by(&:scheduled_for)&.judge_id
      VACOLS::Staff.find_by_sdomainid(User.find_by_id(user_id)&.css_id)&.sattyid
    else
      Appeal.find_by(uuid: appeal[:case_id])&.hearings&.select(&:held?)&.max_by(&:scheduled_for)&.judge_id
    end
  end

  def num_oldest_priority_appeals_for_judge_by_docket(distribution, num)
    return {} unless num > 0

    mapped_dockets = dockets.flat_map do |sym, docket|
      docket.age_of_n_oldest_priority_appeals_available_to_judge(
        distribution.judge, num
      ).map { |age| [age, sym] }
    end

    mapped_dockets.sort_by { |age, _| age }
      .first(num)
      .group_by { |_, sym| sym }
      .transform_values(&:count)
  end

  def num_oldest_nonpriority_appeals_for_judge_by_docket(distribution, num)
    return {} unless num > 0

    mapped_dockets = dockets.flat_map do |sym, docket|
      docket.age_of_n_oldest_nonpriority_appeals_available_to_judge(
        distribution.judge, num
      ).map { |age| [age, sym] }
    end

    mapped_dockets.sort_by { |age, _| age }
      .first(num)
      .group_by { |_, sym| sym }
      .transform_values(&:count)
  end
end
# rubocop:enable Metrics/ModuleLength
