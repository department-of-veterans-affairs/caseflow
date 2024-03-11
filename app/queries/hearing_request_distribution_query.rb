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
    return not_genpop_appeals if genpop == "not_genpop"

    if genpop == "only_genpop"
      return [not_genpop_appeals, only_genpop_appeals].flatten if FeatureToggle.enabled?(:acd_exclude_from_affinity) &&
                                                                  judge.present?

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
    base_relation.most_recent_hearings.tied_to_distribution_judge(judge)
  end

  def only_genpop_appeals
    no_hearings_or_no_held_hearings = with_no_hearings.or(with_no_held_hearings)

    # returning early as most_recent_held_hearings_not_tied_to_any_judge is redundant
    if @use_by_docket_date &&
       !(FeatureToggle.enabled?(:acd_cases_tied_to_judges_no_longer_with_board) ||
        FeatureToggle.enabled?(:acd_exclude_from_affinity))
      return [
        with_held_hearings,
        no_hearings_or_no_held_hearings
      ].flatten.uniq
    end

    # We are combining two queries using an array because using `or` doesn't work
    # due to incompatibilities between the two queries.
    [
      most_recent_held_hearings_not_tied_to_any_judge,
      most_recent_held_hearings_exceeding_affinity_threshold,
      most_recent_held_hearings_tied_to_ineligible_judge,
      no_hearings_or_no_held_hearings,
      most_recent_held_hearings_tied_to_judges_with_exclude_appeals_from_affinity
    ].flatten.uniq
  end

  def most_recent_held_hearings_exceeding_affinity_threshold
    base_relation.most_recent_hearings.exceeding_affinity_threshold
  end

  def most_recent_held_hearings_not_tied_to_any_judge
    base_relation.most_recent_hearings.not_tied_to_any_judge
  end

  def with_no_hearings
    base_relation.with_no_hearings
  end

  def with_no_held_hearings
    base_relation.with_no_held_hearings
  end

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
