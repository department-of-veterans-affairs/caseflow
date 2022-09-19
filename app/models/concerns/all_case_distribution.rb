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

  def priority_push_distribution(limit)
    @rem = 0
    @appeals = []
    # Distribute <limit> number of cases, regardless of docket type, oldest first.
    distribute_priority_appeals_from_all_dockets_by_age_to_limit(limit, style: "push")
    @appeals
  end

  def requested_distribution
    @appeals = []
    @rem = remaining_capacity
    @nonpriority_iterations = 0

    distribute_priority_appeals_from_all_dockets_by_age_to_limit(@rem, style: "request")

    # Distribute the oldest nonpriority appeals from any docket if we haven't distributed {batch_size} appeals
    distribute_nonpriority_appeals_from_all_dockets_by_age_to_limit(@rem) until @rem <= 0
    @appeals
  end

  def collect_appeals
    appeals = yield
    @rem -= appeals.count
    @appeals += appeals
    appeals
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
      nonpriority_iterations: @nonpriority_iterations,
      remaining_capacity: remaining_capacity,
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

  def num_oldest_priority_appeals_for_judge_by_docket(distribution, num)
    return {} unless num > 0

    dockets
      .flat_map { |sym, docket| docket.age_of_n_oldest_priority_appeals_available_to_judge(distribution.judge, num).map { |age| [age, sym] } }
      .sort_by { |age, _| age }
      .first(num)
      .group_by { |_, sym| sym }
      .transform_values(&:count)
  end

  def num_oldest_nonpriority_appeals_for_judge_by_docket(distribution, num)
    return {} unless num > 0

    dockets
      .flat_map { |sym, docket| docket.age_of_n_oldest_nonpriority_appeals_available_to_judge(distribution.judge, num).map { |age| [age, sym] } }
      .sort_by { |age, _| age }
      .first(num)
      .group_by { |_, sym| sym }
      .transform_values(&:count)
  end
end
