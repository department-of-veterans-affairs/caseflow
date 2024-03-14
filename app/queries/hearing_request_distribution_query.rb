# frozen_string_literal: true

class HearingRequestDistributionQuery
  include DistributionScopes

  def initialize(base_relation:, genpop:, judge: nil, use_by_docket_date: false)
    @base_relation = base_relation.extending(DistributionScopes)
    @genpop = genpop
    @judge = judge
    @use_by_docket_date = use_by_docket_date
  end

  def call
    case genpop
    when "not_genpop"
      not_genpop_appeals
    when "only_genpop"
      # If the feature toggle is enabled and a judge is present, we return both not_genpop and only_genpop appeals.
      # If the feature toggle is disabled or a judge isn't present, then we only return only_genpop appeals.
      # This ensures that feature tests don't fail due to missing configurations.
      if FeatureToggle.enabled?(:acd_exclude_from_affinity) && judge.present?
        [not_genpop_appeals, only_genpop_appeals]
      else
        only_genpop_appeals
      end
    when "any"
      # We are returning an array of arrays in order to process the
      # "not_genpop_appeals" separately from the "only_genpop_appeals" in
      # HearingRequestCaseDistributor in order to accurately populate the `genpop`
      # field in the `DistributedCase`. The last step in the automatic case
      # distribution process is to create `DistributedCase`s for the Distribution.
      # For the Hearing Docket, a DistributedCase validates the presence of the
      # genpop attribute. This is used for reporting purposes and so we can
      # verify that the algorithm is correct. For example, if we found a
      # DistributedCase with `genpop_query` set to "not_genpop", but its `genpop`
      # field was set to `true`, that would indicate a bug.
      [not_genpop_appeals, only_genpop_appeals]
    end
  end

  def self.ineligible_judges_id_cache
    Rails.cache.fetch("case_distribution_ineligible_judges")&.pluck(:id)&.reject(&:blank?) || []
  end

  private

  attr_reader :base_relation, :genpop, :judge

  # use nongenpop appeals as the base
  def not_genpop_appeals
    # also handles ama_hearing_case_affinity_days == "infinite"
    base_query = base_relation.most_recent_hearings.tied_to_distribution_judge(judge)

    # handling AMA Hearing Case Affinity Days
    if case_affinity_days_lever_value_is_selected?(CaseDistributionLever.ama_hearing_case_affinity_days)
      base_query = base_query.affinitized_ama_affinity_cases
    end

    # handling AOD AMA Hearing Case AOD Affinity Days
    if case_affinity_days_lever_value_is_selected?(CaseDistributionLever.ama_hearing_case_aod_affinity_days)
      base_query = base_query.joins(with_assigned_distribution_task_sql)
        .or(base_query.ama_aod_hearing_original_appeals)
    elsif CaseDistributionLever.ama_hearing_case_aod_affinity_days == "infinite"
      base_query = base_query.joins(with_assigned_distribution_task_sql)
        .or(base_query.always_ama_aod_hearing_original_appeals)
    end

    base_query.distinct
  end

  def only_genpop_appeals
    result = if case_affinity_days_lever_value_is_selected?(CaseDistributionLever.ama_hearing_case_affinity_days)
               base_relation_with_joined_most_recent_hearings_and_dist_task.expired_ama_affinity_cases
             else
               base_relation_with_joined_most_recent_hearings_and_dist_task.always_ama_affinity_cases
             end

    if FeatureToggle.enabled?(:acd_cases_tied_to_judges_no_longer_with_board)
      result = result.or(
        base_relation_with_joined_most_recent_hearings_and_dist_task.tied_to_ineligible_judge
      )
    end

    if FeatureToggle.enabled?(:acd_exclude_from_affinity)
      result = result.or(
        base_relation_with_joined_most_recent_hearings_and_dist_task.tied_to_judges_with_exclude_appeals_from_affinity
      )
    end

    result = result.or(base_relation_with_joined_most_recent_hearings_and_dist_task.not_tied_to_any_judge)

    # Note: with_no_held_hearings is commented out due to different join shapes. Consider refactoring.
    # result = result.or(base_relation_with_joined_most_recent_hearings_and_dist_task.with_no_held_hearings)

    # The base result doesn't retrieve appeals without hearings, so we add them and ensure the list is unique.
    [result, with_no_hearings, with_no_held_hearings].flatten.uniq
  end

  def base_relation_with_joined_most_recent_hearings_and_dist_task
    base_relation.joins(with_assigned_distribution_task_sql).most_recent_hearings
  end

  def ama_affinity_hearing_appeals_genpop_value
    base_relation.most_recent_hearings.expired_ama_affinity_cases
  end

  def most_recent_held_hearings_always_ama_aod_hearing_original_appeals
    base_relation.always_ama_aod_hearing_original_appeals.not_tied_to_ineligible_judge
  end

  def most_recent_held_hearings_not_tied_to_any_judge
    base_relation.most_recent_hearings.not_tied_to_any_judge
  end

  delegate :with_no_hearings, to: :base_relation

  delegate :with_no_held_hearings, to: :base_relation

  def with_held_hearings
    base_relation.most_recent_hearings.with_held_hearings
  end

  def most_recent_held_hearings_tied_to_ineligible_judge
    base_relation.most_recent_hearings.tied_to_ineligible_judge
  end

  def most_recent_held_hearings_tied_to_judges_with_exclude_appeals_from_affinity
    base_relation.most_recent_hearings.tied_to_judges_with_exclude_appeals_from_affinity
  end
end
