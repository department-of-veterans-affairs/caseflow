# frozen_string_literal: true

class BusinessLine < Organization
  def tasks_url
    "/decision_reviews/#{url}"
  end

  def in_progress_tasks(
    _sort_by: "",
    sort_order: "desc",
    search_query: "",
    _filters: []
  )

    QueryBuilder.new(
      query_type: :in_progress,
      search_query: search_query,
      sort_order: sort_order,
      parent: self
    ).build_query
  end

  def completed_tasks(
    _sort_by: "",
    sort_order: "desc",
    search_query: "",
    _filters: []
  )

    QueryBuilder.new(
      query_type: :completed,
      search_text: search_query,
      sort_order: sort_order,
      parent: self
    ).build_query
  end

  class QueryBuilder
    attr_accessor :search_query, :query_type, :sort_order, :parent
    NUMBER_OF_SEARCH_FIELDS = 2

    def initialize(query_type: :in_progress, search_query: "", sort_order: :desc, parent: business_line)
      @query_type = query_type
      @search_query = search_query
      @sort_order = sort_order
      @parent = parent
    end

    # Order will need to be changed when it is implemented
    def build_query
      Task.select(Arel.star)
        .from(combined_decision_review_tasks_query)
        .includes(*decision_review_task_includes)
        .order(default_order_clause)
    end

    private

    def business_line_id
      @parent.id
    end

    def decision_review_task_includes
      [:assigned_to, :appeal]
    end

    def issue_count
      # Issue count alias for sorting and serialization
      "COUNT(request_issues.id) AS issue_count"
    end

    # Alias for claimant_name for sorting and serialization
    # This is Postgres specific since it uses CONCAT vs ||
    def claimant_name
      "COALESCE("\
      "NULLIF(CONCAT(unrecognized_party_details.name, ' ', unrecognized_party_details.last_name), ' '), "\
      "NULLIF(CONCAT(people.first_name, ' ', people.last_name), ' '), "\
      "CONCAT(veterans.first_name, ' ', veterans.last_name))"
    end

    def claimant_name_alias
      "#{claimant_name} AS claimant_name"
    end

    # Alias of veteran participant id for serialization and sorting
    def participant_id
      "veterans.participant_id as veteran_participant_id"
    end

    # All join clauses

    # Note: .left_joins(ama_appeal: :request_issues)
    # No longer works in the same way as the other joins because left outer join is forced to the end of the query by AR
    def board_grant_effectuation_task_appeals_requests_join
      "LEFT OUTER JOIN appeals ON appeals.id = tasks.appeal_id AND tasks.appeal_type = 'Appeal' "\
      "LEFT OUTER JOIN request_issues ON request_issues.decision_review_id = appeals.id"\
          " AND request_issues.decision_review_type = 'Appeal'"
    end

    def veterans_join
      "INNER JOIN veterans on veterans.file_number = veteran_file_number"
    end

    def claimants_join
      "LEFT JOIN claimants "\
      "ON claimants.decision_review_id = tasks.appeal_id AND claimants.decision_review_type = tasks.appeal_type"
    end

    def unrecognized_appellants_join
      "LEFT JOIN unrecognized_appellants ON claimants.id = unrecognized_appellants.claimant_id"
    end

    def party_details_join
      "LEFT JOIN unrecognized_party_details "\
      "ON unrecognized_appellants.unrecognized_party_detail_id = unrecognized_party_details.id"
    end

    def people_join
      "LEFT JOIN people ON claimants.participant_id = people.participant_id"
    end

    # The NUMBER_OF_SEARCH_FIELDS constant reflects the number of searchable fields here for where interpolation later
    def search_all_clause
      if search_query.present?
        # "veterans.participant_id LIKE ? "\
        # "OR ((veterans.first_name ILIKE ? OR veterans.last_name ILIKE ?) AND veteran_is_not_claimant IS NOT TRUE) "\
        # "OR ((unrecognized_party_details.name ILIKE ? OR unrecognized_party_details.last_name ILIKE ? "\
        # "OR people.first_name ILIKE ? OR people.last_name ILIKE ?) AND veteran_is_not_claimant IS TRUE)"
        "veterans.participant_id LIKE ? "\
        "OR #{claimant_name} ILIKE ? "
      else
        ""
      end
    end

    def group_by_columns
      "tasks.id, veterans.participant_id, veterans.first_name, veterans.last_name, "\
      "unrecognized_party_details.name, unrecognized_party_details.last_name, people.first_name, people.last_name"
    end

    # Uses an array to insert the searched text into all of the searchable fields since it's the same text for all
    def search_values
      searching_text = "%#{search_query}%"
      Array.new(NUMBER_OF_SEARCH_FIELDS, searching_text)
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
        return Arel::Nodes::UnionAll.new(
          appeals_on_request_issues,
          board_grant_effectuation_tasks
        )
      end

      appeals_on_request_issues
    end

    # Specific case for BoardEffectuationGrantTasks to include them in the result set
    # if the :board_grant_effectuation_task FeatureToggle is enabled for the current user.
    def board_grant_effectuation_tasks
      tasks_query = Task.select(Task.arel_table[Arel.star], issue_count, claimant_name_alias, participant_id)
        .joins(board_grant_effectuation_task_appeals_requests_join)
        .joins(veterans_join)
        .joins(claimants_join)
        .joins(people_join)
        .joins(unrecognized_appellants_join)
        .joins(party_details_join)
        .where(board_grant_effectuation_task_constraints)
        .where(search_all_clause, *search_values)
        .group(group_by_columns)

      tasks_query = if @query_type == :in_progress
                      tasks_query.open
                    else
                      tasks_query.recently_completed
                    end
      tasks_query.arel
    end

    def decision_reviews_on_request_issues(join_constraint)
      tasks_query = Task.select(Task.arel_table[Arel.star], issue_count, claimant_name_alias, participant_id)
        .joins(join_constraint)
        .joins(veterans_join)
        .joins(claimants_join)
        .joins(people_join)
        .joins(unrecognized_appellants_join)
        .joins(party_details_join)
        .where(query_constaints)
        .where(search_all_clause, *search_values)
        .group(group_by_columns)

      tasks_query = if @query_type == :in_progress
                      tasks_query.open
                    else
                      tasks_query.recently_completed
                    end
      tasks_query.arel
    end

    def combined_decision_review_tasks_query
      union_query = Arel::Nodes::UnionAll.new(
        Arel::Nodes::UnionAll.new(
          higher_level_reviews_on_request_issues,
          supplemental_claims_on_request_issues
        ),
        ama_appeals_query
      )

      Arel::Nodes::As.new(union_query, Task.arel_table)
    end

    def query_constaints
      if @query_type == :in_progress
        {
          # Don't retrieve any tasks with closed issues or issues with ineligible reasons for in progress
          assigned_to: business_line_id,
          "request_issues.closed_at": nil,
          "request_issues.ineligible_reason": nil
        }
      else
        {
          assigned_to: business_line_id
        }
      end
    end

    def board_grant_effectuation_task_constraints
      {
        assigned_to: business_line_id,
        'tasks.type': BoardGrantEffectuationTask.name
      }
    end

    # TODO: Needs to be updated to work with ordering
    def default_order_clause
      if @query_type == :in_progress
        {
          assigned_at: sort_order.to_sym
        }
      else
        {
          closed_at: sort_order.to_sym
        }
      end
    end
  end
end
