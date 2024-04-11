# frozen_string_literal: true

class HearingRequestDistributionQuery
  include DistributionScopes

  def initialize(base_relation:, genpop:, judge: nil, use_by_docket_date: false)
    @base_relation = base_relation.extending(DistributionScopes)
    @genpop = genpop
    @judge = judge
    @use_by_docket_date = use_by_docket_date
  end

  def call # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return not_genpop_appeals if genpop == "not_genpop"

    if genpop == "only_genpop"
      include_feature = FeatureToggle.enabled?(:acd_exclude_from_affinity) ||
                        (CaseDistributionLever.ama_hearing_case_affinity_days == Constants.ACD_LEVERS.omit &&
                        CaseDistributionLever.ama_hearing_case_aod_affinity_days == Constants.ACD_LEVERS.omit)

      return [*not_genpop_appeals, *only_genpop_appeals] if include_feature &&
                                                            judge.present?

      # if the featue toggle is disabled or judge isn't present then the following line will fail feature tests
      return only_genpop_appeals
    end

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
    [not_genpop_appeals, only_genpop_appeals] if genpop == "any"
  end

  def self.ineligible_judges_id_cache
    Rails.cache.fetch("case_distribution_ineligible_judges")&.pluck(:id)&.reject(&:blank?) || []
  end

  private

  attr_reader :base_relation, :genpop, :judge

  def not_genpop_appeals
    ama_non_aod_hearing_query = generate_ama_not_genpop_non_aod_hearing_query(base_relation)
    ama_aod_hearing_query = generate_ama_not_genpop_aod_hearing_query(base_relation)

    ama_non_aod_hearing_query.or(ama_aod_hearing_query).uniq
  end

  def only_genpop_appeals
    ama_non_aod_hearing_query = generate_ama_only_genpop_non_aod_hearing_query(base_relation)
    ama_aod_hearing_query = generate_ama_only_genpop_aod_hearing_query(base_relation)
    hearings_with_no_judge = base_relation.most_recent_hearings.not_tied_to_any_judge

    result = ama_non_aod_hearing_query.or(ama_aod_hearing_query).or(hearings_with_no_judge)

    if FeatureToggle.enabled?(:acd_cases_tied_to_judges_no_longer_with_board)
      result = result.or(
        base_relation
          .most_recent_hearings
          .tied_to_ineligible_judge
      )
    end

    if FeatureToggle.enabled?(:acd_exclude_from_affinity)
      result = result.or(
        base_relation
          .most_recent_hearings
          .tied_to_judges_with_exclude_appeals_from_affinity
      )
    end

    # the base result is doing an inner join with hearings so it isn't retrieving any appeals that have no hearings
    # yet, so we add with_no_hearings to retrieve those appeals
    no_hearings_or_no_held_hearings = with_no_hearings.or(with_no_held_hearings)

    [*result, *no_hearings_or_no_held_hearings].uniq
  end

  def generate_ama_not_genpop_non_aod_hearing_query(base_relation)
    query =
      if case_affinity_days_lever_value_is_selected?(CaseDistributionLever.ama_hearing_case_affinity_days)
        base_relation
          .most_recent_hearings
          .tied_to_distribution_judge(judge)
          .ama_non_aod_hearing_appeals
          .affinitized_ama_affinity_cases(CaseDistributionLever.ama_hearing_case_affinity_days)
      elsif CaseDistributionLever.ama_hearing_case_affinity_days == Constants.ACD_LEVERS.infinite
        base_relation
          .most_recent_hearings
          .tied_to_distribution_judge(judge)
          .ama_non_aod_hearing_appeals
      elsif CaseDistributionLever.ama_hearing_case_affinity_days == Constants.ACD_LEVERS.omit
        base_relation
          .most_recent_hearings
          .join_distribution_tasks
          .none
      end

    query
  end

  def generate_ama_not_genpop_aod_hearing_query(base_relation)
    query =
      if case_affinity_days_lever_value_is_selected?(CaseDistributionLever.ama_hearing_case_aod_affinity_days)
        base_relation
          .most_recent_hearings
          .tied_to_distribution_judge(judge)
          .ama_aod_hearing_appeals
          .affinitized_ama_affinity_cases(CaseDistributionLever.ama_hearing_case_aod_affinity_days)
      elsif CaseDistributionLever.ama_hearing_case_aod_affinity_days == Constants.ACD_LEVERS.infinite
        base_relation
          .most_recent_hearings
          .tied_to_distribution_judge(judge)
          .ama_aod_hearing_appeals
      elsif CaseDistributionLever.ama_hearing_case_aod_affinity_days == Constants.ACD_LEVERS.omit
        base_relation
          .most_recent_hearings
          .join_distribution_tasks
          .none
      end

    query
  end

  def generate_ama_only_genpop_non_aod_hearing_query(base_relation)
    query =
      if case_affinity_days_lever_value_is_selected?(CaseDistributionLever.ama_hearing_case_affinity_days)
        base_relation
          .most_recent_hearings
          .join_distribution_tasks
          .ama_non_aod_hearing_appeals
          .expired_ama_affinity_cases(CaseDistributionLever.ama_hearing_case_affinity_days)
      elsif CaseDistributionLever.ama_hearing_case_affinity_days == Constants.ACD_LEVERS.infinite
        base_relation
          .most_recent_hearings
          .join_distribution_tasks
          .none
      elsif CaseDistributionLever.ama_hearing_case_affinity_days == Constants.ACD_LEVERS.omit
        base_relation
          .most_recent_hearings
          .join_distribution_tasks
          .with_held_hearings
          .ama_non_aod_hearing_appeals
      end

    query
  end

  def generate_ama_only_genpop_aod_hearing_query(base_relation)
    query =
      if case_affinity_days_lever_value_is_selected?(CaseDistributionLever.ama_hearing_case_aod_affinity_days)
        base_relation
          .most_recent_hearings
          .join_distribution_tasks
          .ama_aod_hearing_appeals
          .expired_ama_affinity_cases(CaseDistributionLever.ama_hearing_case_aod_affinity_days)
      elsif CaseDistributionLever.ama_hearing_case_aod_affinity_days == Constants.ACD_LEVERS.infinite
        base_relation
          .most_recent_hearings
          .join_distribution_tasks
          .none
      elsif CaseDistributionLever.ama_hearing_case_aod_affinity_days == Constants.ACD_LEVERS.omit
        base_relation
          .most_recent_hearings
          .join_distribution_tasks
          .with_held_hearings
          .ama_aod_hearing_appeals
      end

    query
  end

  delegate :with_no_hearings, to: :base_relation
  delegate :with_no_held_hearings, to: :base_relation
end
