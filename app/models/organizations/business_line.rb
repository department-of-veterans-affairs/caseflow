# frozen_string_literal: true

class BusinessLine < Organization
  def tasks_url
    "/decision_reviews/#{url}"
  end

  # Example Params:
  # sort_order: 'desc',
  # sort_by: 'assigned_at',
  # filters: [],
  # search_query: 'Bob'
  def in_progress_tasks(pagination_params = {})
    QueryBuilder.new(
      query_type: :in_progress,
      query_params: pagination_params,
      parent: self
    ).build_query
  end

  def completed_tasks(pagination_params = {})
    QueryBuilder.new(
      query_type: :completed,
      query_params: pagination_params,
      parent: self
    ).build_query
  end

  def in_progress_tasks_type_counts
    QueryBuilder.new(query_type: :in_progress, parent: self).task_type_count
  end

  def completed_tasks_type_counts
    QueryBuilder.new(query_type: :completed, parent: self).task_type_count
  end

  class QueryBuilder
    attr_accessor :query_type, :parent, :query_params

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

    TASKS_QUERY_TYPE = {
      in_progress: "open",
      completed: "recently_completed"
    }.freeze

    DEFAULT_ORDERING_HASH = {
      in_progress: {
        sort_by: :assigned_at
      },
      completed: {
        sort_by: :closed_at
      }
    }.freeze

    def initialize(query_type: :in_progress, parent: business_line, query_params: {})
      @query_type = query_type
      @parent = parent
      @query_params = query_params

      # Initialize default sorting
      query_params[:sort_by] ||= DEFAULT_ORDERING_HASH[query_type][:sort_by]
      query_params[:sort_order] ||= "desc"
    end

    def build_query
      Task.select(Arel.star)
        .from(combined_decision_review_tasks_query)
        .includes(*decision_review_task_includes)
        .where(task_filter_predicate(query_params[:filters]))
        .order(order_clause)
    end

    def task_type_count
      Task.select(Task.arel_table[:type])
        .from(combined_decision_review_tasks_query)
        .group(Task.arel_table[:type], Task.arel_table[:appeal_type])
        .count
    end

    private

    def business_line_id
      parent.id
    end

    def decision_review_task_includes
      [:assigned_to, :appeal]
    end

    def union_select_statements
      [Task.arel_table[Arel.star], issue_count, claimant_name_alias, participant_id_alias, veteran_ssn_alias]
    end

    def issue_count
      # Issue count alias for sorting and serialization
      "COUNT(request_issues.id) AS issue_count"
    end

    # Alias for claimant_name for sorting and serialization
    # This is Postgres specific since it uses CONCAT vs ||
    def claimant_name
      "COALESCE(NULLIF(CASE "\
      "WHEN veteran_is_not_claimant THEN COALESCE("\
        "NULLIF(CONCAT(unrecognized_party_details.name, ' ', unrecognized_party_details.last_name), ' '), "\
        "NULLIF(CONCAT(people.first_name, ' ', people.last_name), ' '), "\
        "bgs_attorneys.name) "\
      "ELSE CONCAT(veterans.first_name, ' ', veterans.last_name) "\
      "END, ' '), 'claimant')"
    end

    def claimant_name_alias
      "#{claimant_name} AS claimant_name"
    end

    def veteran_ssn_alias
      "veterans.ssn as veteran_ssn"
    end

    # Alias of veteran participant id for serialization and sorting
    def participant_id_alias
      "veterans.participant_id as veteran_participant_id"
    end

    # All join clauses

    # NOTE: .left_joins(ama_appeal: :request_issues)
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

    def bgs_attorneys_join
      "LEFT JOIN bgs_attorneys ON claimants.participant_id = bgs_attorneys.participant_id"
    end

    # These values reflect the number of searchable fields in search_all_clause for where interpolation later
    def number_of_search_fields
      FeatureToggle.enabled?(:decision_review_queue_ssn_column, user: RequestStore[:current_user]) ? 4 : 2
    end

    def search_ssn_and_file_number_clause
      +"OR veterans.ssn LIKE ? "\
      "OR veterans.file_number LIKE ? "
    end

    def search_all_clause
      return "" if query_params[:search_query].blank?

      clause = +"veterans.participant_id LIKE ? "\
               "OR #{claimant_name} ILIKE ? "

      if FeatureToggle.enabled?(:decision_review_queue_ssn_column, user: RequestStore[:current_user])
        clause << search_ssn_and_file_number_clause
      end

      clause
    end

    def group_by_columns
      "tasks.id, veterans.participant_id, veterans.ssn, veterans.first_name, veterans.last_name, "\
      "unrecognized_party_details.name, unrecognized_party_details.last_name, people.first_name, people.last_name, "\
      "veteran_is_not_claimant, bgs_attorneys.name"
    end

    # Uses an array to insert the searched text into all of the searchable fields since it's the same text for all
    def search_values
      searching_text = "%#{query_params[:search_query]}%"
      Array.new(number_of_search_fields, searching_text)
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
      if FeatureToggle.enabled?(:board_grant_effectuation_task, user: RequestStore[:current_user])
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
      Task.select(union_select_statements)
        .send(TASKS_QUERY_TYPE[query_type])
        .joins(board_grant_effectuation_task_appeals_requests_join)
        .joins(veterans_join)
        .joins(claimants_join)
        .joins(people_join)
        .joins(unrecognized_appellants_join)
        .joins(party_details_join)
        .joins(bgs_attorneys_join)
        .where(board_grant_effectuation_task_constraints)
        .where(search_all_clause, *search_values)
        .group(group_by_columns)
        .arel
    end

    def decision_reviews_on_request_issues(join_constraint)
      Task.select(union_select_statements)
        .send(TASKS_QUERY_TYPE[query_type])
        .joins(join_constraint)
        .joins(veterans_join)
        .joins(claimants_join)
        .joins(people_join)
        .joins(unrecognized_appellants_join)
        .joins(party_details_join)
        .joins(bgs_attorneys_join)
        .where(query_constaints)
        .where(search_all_clause, *search_values)
        .group(group_by_columns)
        .arel
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
      {
        in_progress: {
          # Don't retrieve any tasks with closed issues or issues with ineligible reasons for in progress
          assigned_to: business_line_id,
          "request_issues.closed_at": nil,
          "request_issues.ineligible_reason": nil
        },
        completed: {
          assigned_to: business_line_id
        }
      }[query_type]
    end

    def board_grant_effectuation_task_constraints
      {
        assigned_to: business_line_id,
        'tasks.type': BoardGrantEffectuationTask.name
      }
    end

    def order_clause
      if query_params[:sort_by] == "veteran_participant_id"
        return Arel.sql(
          ActiveRecord::Base.send(
            :sanitize_sql_array,
            ["#{query_params[:sort_by]}::int #{query_params[:sort_order]}"]
          )
        )
      end
      {
        query_params[:sort_by] => query_params[:sort_order].to_sym
      }
    end

    # Filtering helpers
    def task_filter_predicate(filters)
      return "" unless filters

      task_filter = locate_task_filter(filters)

      return "" unless task_filter

      # ex: "val"=>["SupplementalClaim|HigherLevelReview"]
      tasks_to_include = task_filter["val"].first.split("|")

      build_task_filter_predicates(tasks_to_include) || ""
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
        filter["col"].include?("decisionReviewType")
      end
    end
  end
end
