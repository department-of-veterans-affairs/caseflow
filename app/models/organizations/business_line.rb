# frozen_string_literal: true

class BusinessLine < Organization
  def tasks_url
    "/decision_reviews/#{url}"
  end

  def included_tabs
    [:in_progress, :completed]
  end

  def tasks_query_type
    {
      in_progress: "open",
      completed: "recently_completed"
    }
  end

  def can_generate_claim_history?
    false
  end

  # Example Params:
  # sort_order: 'desc',
  # sort_by: 'assigned_at',
  # filters: [],
  # search_query: 'Bob'
  def incomplete_tasks(pagination_params = {})
    QueryBuilder.new(
      query_type: :incomplete,
      query_params: pagination_params,
      parent: self
    ).build_query
  end

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

  def incomplete_tasks_type_counts
    QueryBuilder.new(query_type: :incomplete, parent: self).task_type_count
  end

  def incomplete_tasks_issue_type_counts
    QueryBuilder.new(query_type: :incomplete, parent: self).issue_type_count
  end

  def in_progress_tasks_type_counts
    QueryBuilder.new(query_type: :in_progress, parent: self).task_type_count
  end

  def completed_tasks_type_counts
    QueryBuilder.new(query_type: :completed, parent: self).task_type_count
  end

  def in_progress_tasks_issue_type_counts
    QueryBuilder.new(query_type: :in_progress, parent: self).issue_type_count
  end

  def completed_tasks_issue_type_counts
    QueryBuilder.new(query_type: :completed, parent: self).issue_type_count
  end

  def change_history_rows(filters = {})
    QueryBuilder.new(query_params: filters, parent: self).change_history_rows
  end

  # rubocop:disable Metrics/ClassLength
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

    DEFAULT_ORDERING_HASH = {
      incomplete: {
        sort_by: :assigned_at
      },
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

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def issue_type_count
      shared_select_statement = "tasks.id as tasks_id, request_issues.nonrating_issue_category as issue_category"
      appeals_query = Task.send(parent.tasks_query_type[query_type])
        .select(shared_select_statement)
        .joins(ama_appeal: :request_issues)
        .where(query_constraints)
      hlr_query = Task.send(parent.tasks_query_type[query_type])
        .select(shared_select_statement)
        .joins(supplemental_claim: :request_issues)
        .where(query_constraints)
      sc_query = Task.send(parent.tasks_query_type[query_type])
        .select(shared_select_statement)
        .joins(higher_level_review: :request_issues)
        .where(query_constraints)

      nonrating_issue_count = ActiveRecord::Base.connection.execute <<-SQL
        WITH task_review_issues AS (
            #{hlr_query.to_sql}
          UNION ALL
            #{sc_query.to_sql}
          UNION ALL
            #{appeals_query.to_sql}
        )
        SELECT issue_category, COUNT(1) AS nonrating_issue_count
        FROM task_review_issues
        GROUP BY issue_category;
      SQL

      issue_count_options = nonrating_issue_count.reduce({}) do |acc, hash|
        key = hash["issue_category"] || "None"
        acc.merge(key => hash["nonrating_issue_count"])
      end

      # Merge in all of the possible issue types for businessline. Guess that the key is the snakecase url
      # It will add in a count for each category with a count of 0 even if there are no tasks with that issue type
      Constants.ISSUE_CATEGORIES.try(parent.url.snakecase)&.each do |key|
        count = issue_count_options[key] || 0
        issue_count_options[key] = count
      end

      issue_count_options
    end
    # rubocop:enable Metrics/AbcSize

    def change_history_rows
      change_history_sql_block = <<-SQL
        SELECT tasks.id AS task_id, tasks.status AS task_status, request_issues.id AS request_issue_id,
          request_issues_updates.created_at AS request_issue_update_time, decision_issues.description AS decision_description,
          request_issues.benefit_type AS request_issue_benefit_type, request_issues_updates.id AS request_issue_update_id,
          request_issues.id AS actual_request_issue_id, request_issues.created_at AS request_issue_created_at,
          intakes.completed_at AS intake_completed_at, update_users.full_name AS update_user_name,
          intake_users.full_name AS intake_user_name, update_users.station_id AS update_user_station_id,
          intake_users.station_id AS intake_user_station_id, decision_users.full_name AS decision_user_name,
          decision_users.station_id AS decision_user_station_id, decision_issues.created_at AS decision_created_at,
          intake_users.css_id AS intake_user_css_id, decision_users.css_id AS decision_user_css_id, update_users.css_id AS update_user_css_id,
          request_issues_updates.before_request_issue_ids, request_issues_updates.after_request_issue_ids,
          request_issues_updates.withdrawn_request_issue_ids, request_issues_updates.edited_request_issue_ids,
          decision_issues.caseflow_decision_date, request_issues.decision_date_added_at, intakes.veteran_file_number,
          tasks.appeal_type, tasks.appeal_id, request_issues.nonrating_issue_category, request_issues.nonrating_issue_description,
          request_issues.decision_date, decision_issues.disposition, tasks.assigned_at, people.first_name, people.last_name,
          request_decision_issues.decision_issue_id, request_issues.closed_at AS request_issue_closed_at
        FROM tasks
        INNER JOIN request_issues ON request_issues.decision_review_type = tasks.appeal_type
        AND request_issues.decision_review_id = tasks.appeal_id
        LEFT JOIN intakes ON tasks.appeal_type = intakes.detail_type
        AND intakes.detail_id = tasks.appeal_id
        LEFT JOIN request_issues_updates ON request_issues_updates.review_type = tasks.appeal_type
        AND request_issues_updates.review_id = tasks.appeal_id
        LEFT JOIN request_decision_issues ON request_decision_issues.request_issue_id = request_issues.id
        LEFT JOIN decision_issues ON decision_issues.decision_review_id = tasks.appeal_id
        AND decision_issues.decision_review_type = tasks.appeal_type AND decision_issues.id = request_decision_issues.decision_issue_id
        LEFT JOIN claimants ON claimants.decision_review_id = tasks.appeal_id
        AND claimants.decision_review_type = tasks.appeal_type
        LEFT JOIN people ON claimants.participant_id = people.participant_id
        LEFT JOIN users intake_users ON intakes.user_id = intake_users.id
        LEFT JOIN users update_users ON request_issues_updates.user_id = update_users.id
        LEFT JOIN users decision_users ON decision_users.id = tasks.completed_by_id
        WHERE tasks.type = 'DecisionReviewTask'
        AND tasks.assigned_to_type = 'Organization'
        AND tasks.assigned_to_id = '#{parent.id.to_i}'
      SQL

      # Append all of the filter queries to the end of the sql block
      change_history_sql_block += change_history_sql_filter_array.join(" ")

      ActiveRecord::Base.connection.execute change_history_sql_block
    end
    # rubocop:enable Metrics/MethodLength

    private

    #################### Change history filter helpers ############################

    def change_history_sql_filter_array
      [
        # Task status and claim type filtering always happens regardless of params
        task_status_filter,
        claim_type_filter,
        # All the other filters are optional
        task_id_filter,
        dispositions_filter,
        issue_types_filter,
        days_waiting_filter,
        station_id_filter,
        user_css_id_filter
      ].compact
    end

    def task_status_filter
      if query_params[:task_status].present?
        " AND #{where_clause_from_array(Task, :status, query_params[:task_status]).to_sql}"
      else
        " AND tasks.status IN ('assigned', 'in_progress', 'on_hold', 'completed', 'cancelled') "
      end
    end

    def claim_type_filter
      if query_params[:claim_type].present?
        " AND #{where_clause_from_array(Task, :appeal_type, query_params[:claim_type]).to_sql}"
      else
        " AND tasks.appeal_type IN ('HigherLevelReview', 'SupplementalClaim') "
      end
    end

    def task_id_filter
      if query_params[:task_id].present?
        " AND #{where_clause_from_array(Task, :id, query_params[:task_id]).to_sql} "
      end
    end

    def dispositions_filter
      if query_params[:dispositions].present?
        sql = where_clause_from_array(DecisionIssue, :disposition, query_params[:dispositions]).to_sql
        " AND #{sql} "
      end
    end

    def issue_types_filter
      if query_params[:issue_types].present?
        sql = where_clause_from_array(RequestIssue, :nonrating_issue_category, query_params[:issue_types]).to_sql
        " AND #{sql} "
      end
    end

    def days_waiting_filter
      if query_params[:days_waiting].present?
        number_of_days = query_params[:days_waiting][:number_of_days]
        operator = query_params[:days_waiting][:range]
        case operator
        when ">", "<", "="
          <<-SQL
            AND EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - tasks.assigned_at))::integer #{operator} '#{number_of_days.to_i}'
          SQL
        when "between"
          end_days = query_params[:days_waiting][:end_days]
          <<-SQL
            AND EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - tasks.assigned_at))::integer BETWEEN '#{number_of_days.to_i}' AND '#{end_days.to_i}'
          SQL
        end
      end
    end

    def station_id_filter
      if query_params[:facilities].present?
        <<-SQL
          AND
          (
            #{User.arel_table.alias(:intake_users)[:station_id].in(query_params[:facilities]).to_sql}
            OR
            #{User.arel_table.alias(:update_users)[:station_id].in(query_params[:facilities]).to_sql}
            OR
            #{User.arel_table.alias(:decision_users)[:station_id].in(query_params[:facilities]).to_sql}
          )
        SQL
      end
    end

    def user_css_id_filter
      if query_params[:personnel].present?
        <<-SQL
          AND
          (
            #{User.arel_table.alias(:intake_users)[:css_id].in(query_params[:personnel]).to_sql}
            OR
            #{User.arel_table.alias(:update_users)[:css_id].in(query_params[:personnel]).to_sql}
            OR
            #{User.arel_table.alias(:decision_users)[:css_id].in(query_params[:personnel]).to_sql}
          )
        SQL
      end
    end

    #################### End of Change history filter helpers ########################

    def business_line_id
      parent.id
    end

    def decision_review_task_includes
      [:assigned_to, :appeal]
    end

    def union_select_statements
      [
        Task.arel_table[Arel.star],
        issue_count,
        claimant_name_alias,
        participant_id_alias,
        veteran_ssn_alias,
        issue_types,
        issue_types_lower,
        appeal_unique_id_alias
      ]
    end

    def issue_count
      # Issue count alias for sorting and serialization
      "COUNT(request_issues.id) AS issue_count"
    end

    # Alias for the issue_categories on request issues for sorting and serialization
    # This is Postgres specific since it uses STRING_AGG vs GROUP_CONCAT
    def issue_types
      "STRING_AGG(DISTINCT request_issues.nonrating_issue_category, ','"\
      " ORDER BY request_issues.nonrating_issue_category)"\
      " AS issue_types"
    end

    # Bandaid alias for case insensitive ordering
    def issue_types_lower
      "STRING_AGG(DISTINCT LOWER(request_issues.nonrating_issue_category), ','"\
      " ORDER BY LOWER(request_issues.nonrating_issue_category))"\
      " AS issue_types_lower"
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

    def appeal_unique_id_alias
      "uuid as external_appeal_id"
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

    def union_query_join_clauses
      [
        veterans_join,
        claimants_join,
        people_join,
        unrecognized_appellants_join,
        party_details_join,
        bgs_attorneys_join
      ]
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
               "OR #{claimant_name} ILIKE ? "\

      if FeatureToggle.enabled?(:decision_review_queue_ssn_column, user: RequestStore[:current_user])
        clause << search_ssn_and_file_number_clause
      end

      clause
    end

    def group_by_columns
      "tasks.id, uuid, veterans.participant_id, veterans.ssn, veterans.first_name, veterans.last_name, "\
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

    # Specific case for BoardEffectuationGrantTasks to include them in the result set
    # if the :board_grant_effectuation_task FeatureToggle is enabled for the current user.
    def board_grant_effectuation_tasks
      decision_reviews_on_request_issues(board_grant_effectuation_task_appeals_requests_join,
                                         board_grant_effectuation_task_constraints)
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

    def decision_reviews_on_request_issues(join_constraint, where_constraints = query_constraints)
      Task.select(union_select_statements)
        .send(parent.tasks_query_type[query_type])
        .joins(join_constraint)
        .joins(*union_query_join_clauses)
        .where(where_constraints)
        .where(search_all_clause, *search_values)
        .where(issue_type_filter_predicate(query_params[:filters]))
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

    def query_constraints
      {
        incomplete: {
          # Don't retrieve any tasks with closed issues or issues with ineligible reasons for incomplete
          assigned_to: parent,
          "request_issues.closed_at": nil,
          "request_issues.ineligible_reason": nil
        },
        in_progress: {
          # Don't retrieve any tasks with closed issues or issues with ineligible reasons for in progress
          assigned_to: parent,
          "request_issues.closed_at": nil,
          "request_issues.ineligible_reason": nil
        },
        completed: {
          assigned_to: parent
        }
      }[query_type]
    end

    def board_grant_effectuation_task_constraints
      {
        assigned_to: parent,
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

    def issue_type_filter_predicate(filters)
      return "" unless filters

      issue_type_filter = locate_issue_type_filter(filters)

      return "" unless issue_type_filter

      # ex: "val"=>["Caregiver | Other|Beneficiary Travel"]
      tasks_to_include = issue_type_filter["val"].first.split(/(?<!\s)\|(?!\s)/)

      build_issue_type_filter_predicates(tasks_to_include) || ""
    end

    def build_issue_type_filter_predicates(tasks_to_include)
      first_task_name, *remaining_task_names = tasks_to_include

      first_task_name = nil if first_task_name == "None"

      filter = RequestIssue.arel_table[:nonrating_issue_category].eq(first_task_name)

      remaining_task_names.each do |task_name|
        task_name = nil if task_name == "None"
        filter = filter.or(RequestIssue.arel_table[:nonrating_issue_category].eq(task_name))
      end

      filtered_ids = decision_review_requests_union_subquery(filter)

      ["tasks.id IN (?)", filtered_ids]
    end

    def decision_review_requests_union_subquery(filter)
      base_query = Task.select("tasks.id").send(parent.tasks_query_type[query_type])
      union_query = Arel::Nodes::UnionAll.new(
        Arel::Nodes::UnionAll.new(
          base_query
            .joins(higher_level_review: :request_issues).where(query_constraints).where(filter).arel,
          base_query
            .joins(supplemental_claim: :request_issues).where(query_constraints).where(filter).arel
        ),
        base_query.joins(ama_appeal: :request_issues).where(query_constraints).where(filter).arel
      )

      # Grab all the ids and use it in the where clause
      Task.from(Arel::Nodes::As.new(union_query, Task.arel_table)).pluck(:id)
    end

    def locate_issue_type_filter(filters)
      # Example filter:
      # [{"col"=>["issueTypesColumn"], "val"=>["Apportionment|CHAMPVA"]},
      # {"col"=>["decisionReviewType"], "val"=>["HigherLevelReview"]}]
      parsed_filters = parse_filters(filters)

      parsed_filters.find do |filter|
        filter["col"].include?("issueTypesColumn")
      end
    end

    def where_clause_from_array(table_class, column, values_array)
      table_class.arel_table[column].in(values_array)
    end
  end
  # rubocop:enable Metrics/ClassLength
end

require_dependency "vha_business_line"
