# frozen_string_literal: true

class HearingRequestDistributionQuery
  def initialize(base_relation:, genpop:, judge: nil, use_by_docket_date: false)
    @base_relation = base_relation.extending(Scopes)
    @genpop = genpop
    @judge = judge
    @use_by_docket_date = use_by_docket_date
  end

  def call
    return not_genpop_appeals if genpop == "not_genpop"

    return only_genpop_appeals if genpop == "only_genpop"

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
    if @use_by_docket_date && !FeatureToggle.enabled?(:acd_cases_tied_to_judges_no_longer_with_board)
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
      no_hearings_or_no_held_hearings
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

  module Scopes
    include DistributionScopes
    def most_recent_hearings
      query = <<-SQL
        INNER JOIN
        (SELECT h.appeal_id, max(hd.scheduled_for) as latest_scheduled_for
        FROM hearings h
        JOIN hearing_days hd on h.hearing_day_id = hd.id
        GROUP BY
        h.appeal_id
        ) as latest_date_by_appeal
        ON appeals.id = latest_date_by_appeal.appeal_id
        AND hearing_days.scheduled_for = latest_date_by_appeal.latest_scheduled_for
      SQL

      joins(query, hearings: :hearing_day)
    end

    def tied_to_distribution_judge(judge)
      joins(with_assigned_distribution_task_sql)
        .where(hearings: { disposition: "held", judge_id: judge.id })
        .where("distribution_task.assigned_at > ?",
               CaseDistributionLever.ama_hearing_case_affinity_days.days.ago)
    end

    def tied_to_ineligible_judge
      where(hearings: { disposition: "held", judge_id: HearingRequestDistributionQuery.ineligible_judges_id_cache })
        .where("1 = ?", FeatureToggle.enabled?(:acd_cases_tied_to_judges_no_longer_with_board) ? 1 : 0)
    end

    # If an appeal has exceeded the affinity, it should be returned to genpop.
    def exceeding_affinity_threshold
      joins(with_assigned_distribution_task_sql)
        .where(hearings: { disposition: "held" })
        .where("distribution_task.assigned_at <= ?", CaseDistributionLever.ama_hearing_case_affinity_days.days.ago)
    end

    # Historical note: We formerly had not_tied_to_any_active_judge until CASEFLOW-1928,
    # when that distinction became irrelevant because cases become genpop after 30 days anyway.
    def not_tied_to_any_judge
      where(hearings: { disposition: "held", judge_id: nil })
    end

    def with_no_hearings
      left_joins(:hearings).where(hearings: { id: nil })
    end

    def with_no_held_hearings
      left_joins(:hearings).where.not(hearings: { disposition: "held" })
    end

    def with_held_hearings
      where(hearings: { disposition: "held" })
    end
  end
end
