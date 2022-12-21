# frozen_string_literal: true

class BusinessLine < Organization
  TASK_FILTER_PREDICATES = {
    "VeteranRecordRequest" => Task.arel_table[:type].eq(VeteranRecordRequest.name),
    "BoardGrantEffectuationTask" => Task.arel_table[:type].eq(BoardGrantEffectuationTask.name),
    "HigherLevelReview" => Task.arel_table[:appeal_type]
      .eq("HigherLevelReview")
      .and(Task.arel_table[:type].eq(DecisionReviewTask.name)),
    "SupplementalClaim" => Task.arel_table[:appeal_type]
      .eq("SupplementalClaim")
      .and(Task.arel_table[:type].eq(DecisionReviewTask.name))
  }.freeze

  delegate :in_progress_tasks, :completed_tasks, to: :decision_review_tasks_query_manager

  def tasks_url
    "/decision_reviews/#{url}"
  end

  def in_progress_tasks(
    _sort_by: "",
    sort_order: "desc",
    filters: []
  )
    Task.select(Arel.star)
      .from(combined_decision_review_tasks_query)
      .includes(*decision_review_task_includes)
      .where(task_filter_predicate(filters))
      .order(assigned_at: sort_order.to_sym)
  end

  def completed_tasks(
    _sort_by: "",
    sort_order: "desc",
    filters: []
  )
    tasks
      .recently_completed
      .includes(*decision_review_task_includes)
      .where(task_filter_predicate(filters))
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

  def ama_appeals_query
    if FeatureToggle.enabled?(:board_grant_effectuation_task, user: :current_user)
      return Arel::Nodes::Union.new(
        appeals_on_request_issues,
        board_grant_effectuation_tasks
      )
    end

    appeals_on_request_issues
  end

  # Specific case for BoardEffectuationGrantTasks to include them in the result set
  # if the :board_grant_effectuation_task FeatureToggle is enabled for the current user.
  def board_grant_effectuation_tasks
    Task.select(Task.arel_table[Arel.star], issue_count)
      .open
      .left_joins(ama_appeal: :request_issues)
      .where(Task.arel_table[:type].eq(BoardGrantEffectuationTask.name))
      .where(assigned_to: self)
      .group("tasks.id")
      .arel
  end

  def decision_reviews_on_request_issues(join_constraint)
    Task.select(Task.arel_table[Arel.star], issue_count)
      .open
      .joins(join_constraint)
      .where(active_request_issue_constraints)
      .group("tasks.id")
      .arel
  end

  def combined_decision_review_tasks_query
    union_query = Arel::Nodes::Union.new(
      Arel::Nodes::Union.new(
        higher_level_reviews_on_request_issues,
        supplemental_claims_on_request_issues
      ),
      ama_appeals_query
    )

    Arel::Nodes::As.new(union_query, Task.arel_table)
  end

  def active_request_issue_constraints
    {
      assigned_to: self,
      "request_issues.closed_at": nil,
      "request_issues.ineligible_reason": nil
    }
  end

  def task_filter_predicate(filters)
    task_filter = locate_task_filter(filters)

    # Returns a tautological predicate if a task filter could not be located.
    return "1 = 1" unless task_filter

    # ex: "val"=>["SupplementalClaim|HigherLevelReview"]
    tasks_to_include = task_filter["val"].first.split("|")

    build_task_filter_predicates(tasks_to_include)
  end

  def build_task_filter_predicates(tasks_to_include)
    first_task_name, *remaining_task_names = tasks_to_include

    filter = TASK_FILTER_PREDICATES[first_task_name]

    remaining_task_names.each { |task_name| filter = filter.or(TASK_FILTER_PREDICATES[task_name]) }

    filter
  end

  def parse_filters(filters)
    filters.map { |filter| CGI.parse(filter) }
  end

  def locate_task_filter(filters)
    parsed_filters = parse_filters(filters)

    parsed_filters.find do |filter|
      filter["col"].include?(Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name)
    end
  end
end
