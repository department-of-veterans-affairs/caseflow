# frozen_string_literal: true

module DecisionReviewTasksConcern
  extend ActiveSupport::Concern

  def in_progress_tasks(
    _sort_by: "",
    sort_order: "desc",
    _filters: []
  )
    Task.select(Arel.star)
      .from(combined_decision_review_tasks_query)
      .includes(*decision_review_task_includes)
      .order(assigned_at: sort_order.to_sym)
  end

  def completed_tasks(
    _sort_by: "",
    sort_order: "desc",
    _filters: []
  )
    tasks
      .recently_completed
      .includes(*decision_review_task_includes)
      .order(closed_at: sort_order.to_sym)
  end

  private

  def decision_review_task_includes
    [:assigned_to, :appeal]
  end

  def issue_count
    # Issue count alias for sorting and serialization
    "COUNT(request_issues.id) AS issue_count"
  end

  def higher_level_reviews_on_request_issues
    decision_reviews_on_request_issues(higher_level_review: :request_issues)
  end

  def supplemental_claims_on_request_issues
    decision_reviews_on_request_issues(supplemental_claim: :request_issues)
  end

  def appeals_on_request_issues
    decision_reviews_on_request_issues(ama_appeal: :request_issues)
  end

  def decision_reviews_on_request_issues(join_constraint)
    Task.select(Task.arel_table[Arel.star], issue_count)
      .open
      .joins(join_constraint)
      .where(decision_review_where_predicate)
      .group("tasks.id")
      .arel
  end

  def combined_decision_review_tasks_query
    union_query = Arel::Nodes::Union.new(
      Arel::Nodes::Union.new(
        higher_level_reviews_on_request_issues,
        supplemental_claims_on_request_issues
      ),
      appeals_on_request_issues
    )

    Arel::Nodes::As.new(union_query, Task.arel_table)
  end

  def decision_review_where_predicate
    if FeatureToggle.enabled?(:board_grant_effectuation_task, user: :current_user)
      return board_grant_bypass_constraint
    end

    active_request_issue_constraints
  end

  def active_request_issue_constraints
    {
      assigned_to: id,
      "request_issues.closed_at": nil,
      "request_issues.ineligible_reason": nil
    }
  end

  # Enforces the requirement that all business line tasks in the queue
  # must be associated with a decision review that has at least one active
  # request issue except for BoardGreantEffectuationTasks. This is because those
  # tasks are on appeals that have at least one closed request issue.
  def board_grant_bypass_constraint
    Task.arel_table[:assigned_to_id].eq(id)
      .and(Task.arel_table[:assigned_to_type].eq("Organization"))
      .and(
        RequestIssue.arel_table[:closed_at].eq(nil).and(RequestIssue.arel_table[:ineligible_reason].eq(nil)).or(
          Task.arel_table[:type].eq(BoardGrantEffectuationTask.name)
        )
      )
  end
end
