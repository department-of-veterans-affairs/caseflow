# frozen_string_literal: true

class HearingRequestDistributionQuery
  include DistributionScopes

  def initialize(base_relation:, genpop:, judge: nil, use_by_docket_date: false)
    @base_relation = base_relation.extending(DistributionScopes)
    @genpop = genpop
    @judge = judge
    @use_by_docket_date = use_by_docket_date
  end

  def call # rubocop:disable Metrics/CyclomaticComplexity
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

    []
  end

  def self.ineligible_judges_id_cache
    Rails.cache.fetch("case_distribution_ineligible_judges")&.pluck(:id)&.reject(&:blank?) || []
  end

  private

  attr_reader :base_relation, :genpop, :judge

  def not_genpop_appeals
    ama_non_aod_hearing_query = generate_ama_not_genpop_non_aod_hearing_query(base_relation)
    ama_aod_hearing_query = generate_ama_not_genpop_aod_hearing_query(base_relation)
    non_aod_cavc_query = generate_not_genpop_non_aod_cavc_query(base_relation)
    aod_cavc_query = generate_not_genpop_aod_cavc_query(base_relation)

    [ama_non_aod_hearing_query.or(ama_aod_hearing_query), non_aod_cavc_query, aod_cavc_query].flatten
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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
    no_hearings_or_only_no_held_hearings = []
    no_hearings_or_no_held_hearings.each do |appeal|
      if appeal.hearings.blank? || appeal.hearings.pluck(:disposition).exclude?("held")
        if appeal.cavc? && appeal.appeal_affinity&.affinity_start_date &&
           ((appeal.aod? &&
             appeal.appeal_affinity.affinity_start_date < CaseDistributionLever.cavc_aod_affinity_days.to_i.days.ago) ||
           (appeal.appeal_affinity.affinity_start_date < CaseDistributionLever.cavc_affinity_days.to_i.days.ago))
          no_hearings_or_only_no_held_hearings << appeal
        elsif !appeal.cavc?
          no_hearings_or_only_no_held_hearings << appeal
        end
      end
    end

    [*result, *no_hearings_or_only_no_held_hearings].uniq
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def generate_ama_not_genpop_non_aod_hearing_query(base_relation)
    query =
      if case_affinity_days_lever_value_is_selected?(CaseDistributionLever.ama_hearing_case_affinity_days)
        base_relation
          .most_recent_hearings
          .tied_to_distribution_judge(judge)
          .ama_non_aod_appeals
          .affinitized_ama_affinity_cases(CaseDistributionLever.ama_hearing_case_affinity_days)
      elsif CaseDistributionLever.ama_hearing_case_affinity_days == Constants.ACD_LEVERS.infinite
        base_relation
          .most_recent_hearings
          .tied_to_distribution_judge(judge)
          .ama_non_aod_appeals
      elsif CaseDistributionLever.ama_hearing_case_affinity_days == Constants.ACD_LEVERS.omit
        base_relation
          .most_recent_hearings
          .with_appeal_affinities
          .none
      end

    query
  end

  # rubocop:disable Metrics/MethodLength: Method has too many lines
  def generate_not_genpop_non_aod_cavc_query(base_relation)
    query =
      if case_affinity_days_lever_value_is_selected?(CaseDistributionLever.cavc_affinity_days)
        base_relation
          .with_no_hearings
          .with_cavc_appeals
          .tied_to_distribution_judge(judge)
          .ama_non_aod_appeals
          .affinitized_ama_affinity_cases(CaseDistributionLever.cavc_affinity_days)
      elsif CaseDistributionLever.cavc_affinity_days == Constants.ACD_LEVERS.infinite
        base_relation
          .with_no_hearings
          .with_cavc_appeals
          .tied_to_distribution_judge(judge)
          .ama_non_aod_appeals
      elsif CaseDistributionLever.cavc_affinity_days == Constants.ACD_LEVERS.omit
        base_relation
          .with_no_hearings
          .with_cavc_appeals
          .with_appeal_affinities
          .none
      end

    query
  end
  # rubocop:enable Metrics/MethodLength: Method has too many lines

  # rubocop:disable Metrics/MethodLength: Method has too many lines
  def generate_not_genpop_aod_cavc_query(base_relation)
    query =
      if case_affinity_days_lever_value_is_selected?(CaseDistributionLever.cavc_aod_affinity_days)
        base_relation
          .with_no_hearings
          .with_cavc_appeals
          .tied_to_distribution_judge(judge)
          .ama_aod_appeals
          .affinitized_ama_affinity_cases(CaseDistributionLever.cavc_aod_affinity_days)
      elsif CaseDistributionLever.cavc_aod_affinity_days == Constants.ACD_LEVERS.infinite
        base_relation
          .with_no_hearings
          .with_cavc_appeals
          .tied_to_distribution_judge(judge)
          .ama_aod_appeals
      elsif CaseDistributionLever.cavc_aod_affinity_days == Constants.ACD_LEVERS.omit
        base_relation
          .with_no_hearings
          .with_cavc_appeals
          .with_appeal_affinities
          .none
      end

    query
  end
  # rubocop:enable Metrics/MethodLength: Method has too many lines

  def generate_ama_not_genpop_aod_hearing_query(base_relation)
    query =
      if case_affinity_days_lever_value_is_selected?(CaseDistributionLever.ama_hearing_case_aod_affinity_days)
        base_relation
          .most_recent_hearings
          .tied_to_distribution_judge(judge)
          .ama_aod_appeals
          .affinitized_ama_affinity_cases(CaseDistributionLever.ama_hearing_case_aod_affinity_days)
      elsif CaseDistributionLever.ama_hearing_case_aod_affinity_days == Constants.ACD_LEVERS.infinite
        base_relation
          .most_recent_hearings
          .tied_to_distribution_judge(judge)
          .ama_aod_appeals
      elsif CaseDistributionLever.ama_hearing_case_aod_affinity_days == Constants.ACD_LEVERS.omit
        base_relation
          .most_recent_hearings
          .with_appeal_affinities
          .none
      end

    query
  end

  def generate_ama_only_genpop_non_aod_hearing_query(base_relation)
    query =
      if case_affinity_days_lever_value_is_selected?(CaseDistributionLever.ama_hearing_case_affinity_days)
        base_relation
          .most_recent_hearings
          .with_appeal_affinities
          .ama_non_aod_appeals
          .expired_ama_affinity_cases(CaseDistributionLever.ama_hearing_case_affinity_days)
      elsif CaseDistributionLever.ama_hearing_case_affinity_days == Constants.ACD_LEVERS.infinite
        base_relation
          .most_recent_hearings
          .with_appeal_affinities
          .none
      elsif CaseDistributionLever.ama_hearing_case_affinity_days == Constants.ACD_LEVERS.omit
        base_relation
          .most_recent_hearings
          .with_appeal_affinities
          .with_held_hearings
          .ama_non_aod_appeals
      end

    query
  end

  def generate_ama_only_genpop_aod_hearing_query(base_relation)
    query =
      if case_affinity_days_lever_value_is_selected?(CaseDistributionLever.ama_hearing_case_aod_affinity_days)
        base_relation
          .most_recent_hearings
          .with_appeal_affinities
          .ama_aod_appeals
          .expired_ama_affinity_cases(CaseDistributionLever.ama_hearing_case_aod_affinity_days)
      elsif CaseDistributionLever.ama_hearing_case_aod_affinity_days == Constants.ACD_LEVERS.infinite
        base_relation
          .most_recent_hearings
          .with_appeal_affinities
          .none
      elsif CaseDistributionLever.ama_hearing_case_aod_affinity_days == Constants.ACD_LEVERS.omit
        base_relation
          .most_recent_hearings
          .with_appeal_affinities
          .with_held_hearings
          .ama_aod_appeals
      end

    query
  end

  delegate :with_no_hearings, to: :base_relation
  delegate :with_no_held_hearings, to: :base_relation
end
