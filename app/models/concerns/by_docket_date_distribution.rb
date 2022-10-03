# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module ByDocketDateDistribution
  extend ActiveSupport::Concern
  include CaseDistribution

  private

  def priority_push_distribution(limit)
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

    # If we haven't yet met the priority target, distribute additional priority appeals.
    priority_rem = priority_target.clamp(0, @rem)
    distribute_priority_appeals_from_all_dockets_by_age_to_limit(priority_rem, style: "request")

    # Distribute the oldest nonpriority appeals from any docket if we haven't distributed {batch_size} appeals
    distribute_nonpriority_appeals_from_all_dockets_by_age_to_limit(@rem) until @rem <= 0
    @appeals
  end

  def distribute_priority_appeals_from_all_dockets_by_age_to_limit(limit, style: "request")
    num_oldest_priority_appeals_for_judge_by_docket(self, limit).each do |docket, number_of_appeals_to_distribute|
      collect_appeals do
        next if docket == 'legacy' && true
        
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
      nonpriority_iterations: @nonpriority_iterations,
      algorithm: 'by_docket_date'
    }
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
