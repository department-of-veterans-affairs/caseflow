# frozen_string_literal: true

class HearingRequestDistributionQuery
  def initialize(base_relation:, genpop:, judge: nil)
    @base_relation = base_relation.extending(Scopes)
    @genpop = genpop
    @judge = judge
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

  private

  attr_reader :base_relation, :genpop, :judge

  def not_genpop_appeals
    # (7 June 2021) Hearing request docket "affinity" temporarily removed in
    # https://github.com/department-of-veterans-affairs/caseflow/pull/16326
    #
    # base_relation.most_recent_hearings.tied_to_distribution_judge(judge)
    []
  end

  # We are combining two queries using an array because using `or` doesn't work
  # due to incompatibilities between the two queries.
  def only_genpop_appeals
    # (7 June 2021) Hearing request docket "affinity" temporarily removed in
    # https://github.com/department-of-veterans-affairs/caseflow/pull/16326
    # 
    # no_hearings_or_no_held_hearings = with_no_hearings.or(with_no_held_hearings)
    # [most_recent_held_hearings_not_tied_to_any_active_judge, no_hearings_or_no_held_hearings].flatten
    base_relation.to_a
  end

  def most_recent_held_hearings_not_tied_to_any_active_judge
    base_relation.most_recent_hearings.not_tied_to_any_active_judge
  end

  def with_no_hearings
    base_relation.with_no_hearings
  end

  def with_no_held_hearings
    base_relation.with_no_held_hearings
  end

  module Scopes
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
      where(hearings: { disposition: "held", judge_id: judge.id })
    end

    def not_tied_to_any_active_judge
      judge_css_ids = JudgeTeam.pluck(:name)
      inactive_judges = User.where(css_id: judge_css_ids).where("last_login_at < ?", 60.days.ago).pluck(:id)
      where(hearings: { disposition: "held", judge_id: inactive_judges.append(nil) })
    end

    def with_no_hearings
      left_joins(:hearings).where(hearings: { id: nil })
    end

    def with_no_held_hearings
      left_joins(:hearings).where.not(hearings: { disposition: "held" })
    end
  end
end
