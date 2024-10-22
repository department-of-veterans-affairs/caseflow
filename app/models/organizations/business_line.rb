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

  def pending_tasks(pagination_params = {})
    QueryBuilder.new(
      query_type: :pending,
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

  def pending_tasks_issue_type_counts
    QueryBuilder.new(query_type: :pending, parent: self).issue_type_count
  end

  def pending_tasks_type_counts
    QueryBuilder.new(query_type: :pending, parent: self).task_type_count
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
        .and(Arel.sql("sub_type").not_eq("Remand")),
      "Remand" => Arel.sql("sub_type").eq("Remand")
        .and(Task.arel_table[:type].eq(DecisionReviewTask.name))
    }.freeze

    DEFAULT_ORDERING_HASH = {
      incomplete: {
        sort_by: :assigned_at
      },
      in_progress: {
        sort_by: :assigned_at
      },
      pending: {
        sort_by: :assigned_at
      },
      completed: {
        sort_by: :closed_at
      }
    }.freeze

    USER_TABLE_ALIASES = [
      :intake_users,
      :update_users,
      :decision_users,
      :decision_users_completed_by,
      :requestor,
      :decider
    ].freeze

    def initialize(query_type: :in_progress, parent: business_line, query_params: {})
      @query_type = query_type
      @parent = parent
      @query_params = query_params.dup
      # Initialize default sorting
      @query_params[:sort_by] ||= DEFAULT_ORDERING_HASH[query_type][:sort_by]
      @query_params[:sort_order] ||= "desc"
    end

    def build_query
      Task.select(Arel.star)
        .from(combined_decision_review_tasks_query)
        .includes(*decision_review_task_includes)
        .where(task_filter_predicate(query_params[:filters]))
        .order(order_clause)
    end

    def task_type_query_helper(join_association)
      Task.send(parent.tasks_query_type[query_type])
        .select("tasks.id AS task_id, tasks.type AS task_type")
        .joins(join_association)
        .joins(issue_modification_request_join)
        .where(query_constraints)
        .where(issue_modification_request_filter)
    end

    def task_type_board_grant_helper
      Task.send(parent.tasks_query_type[query_type])
        .select("tasks.id AS task_id, tasks.type AS task_type, 'Appeal' AS decision_review_type")
        .joins(board_grant_effectuation_task_appeals_requests_join)
        .joins(issue_modification_request_join)
        .where(board_grant_effectuation_task_constraints)
        .where(issue_modification_request_filter)
    end

    def issue_type_query_helper(join_association)
      Task.send(parent.tasks_query_type[query_type])
        .select("tasks.id as task_id, request_issues.nonrating_issue_category AS issue_category")
        .joins(join_association)
        .joins(issue_modification_request_join)
        .where(query_constraints)
        .where(issue_modification_request_filter)
    end

    # rubocop:disable Metrics/MethodLength
    def task_type_count
      appeals_query = task_type_query_helper(ama_appeal: :request_issues)
        .select("'Appeal' AS decision_review_type")
      hlr_query = task_type_query_helper(higher_level_review: :request_issues)
        .select("'HigherLevelReview' AS decision_review_type")
      sc_query = task_type_query_helper(supplemental_claim: :request_issues)
        .select("supplemental_claims.type AS decision_review_type")
      board_grant_query = task_type_board_grant_helper

      task_count = ActiveRecord::Base.connection.execute <<-SQL
        WITH task_review_issues AS (
            #{hlr_query.to_sql}
          UNION
            #{sc_query.to_sql}
          UNION
            #{appeals_query.to_sql}
          UNION
            #{board_grant_query.to_sql}
        )
        SELECT task_type, decision_review_type, COUNT(1)
        FROM task_review_issues
        GROUP BY task_type, decision_review_type;
      SQL

      task_count.reduce({}) do |acc, item|
        key = [item["task_type"], item["decision_review_type"]]
        acc[key] = (acc[key] || 0) + item["count"]
        acc
      end
    end

    def issue_type_count
      appeals_query = issue_type_query_helper(ama_appeal: :request_issues)
      hlr_query = issue_type_query_helper(higher_level_review: :request_issues)
      sc_query = issue_type_query_helper(supplemental_claim: :request_issues)

      nonrating_issue_count = ActiveRecord::Base.connection.execute <<-SQL
        WITH task_review_issues AS (
            #{hlr_query.to_sql}
          UNION
            #{sc_query.to_sql}
          UNION
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

    def change_history_rows
      # Generate all of the filter queries to be used in both the HLR and SC block
      sql = Arel.sql(change_history_sql_filter_array.join(" "))
      sanitized_filters = ActiveRecord::Base.sanitize_sql_array([sql])
      sc_type_clauses = ActiveRecord::Base.sanitize_sql_array([sc_type_filter])
      current_timestamp = ActiveRecord::Base.connection.quote(Time.zone.now)

      change_history_sql_block = <<-SQL
        WITH versions_agg AS NOT MATERIALIZED (
          SELECT
              versions.item_id,
              versions.item_type,
              STRING_AGG(versions.object_changes, '|||' ORDER BY versions.id) AS object_changes_array,
              MAX(CASE
                  WHEN versions.object_changes LIKE '%closed_at:%' THEN versions.whodunnit
                  ELSE NULL
              END) AS version_closed_by_id
          FROM
              versions
          INNER JOIN tasks ON tasks.id = versions.item_id
          WHERE versions.item_type = 'Task'
            AND tasks.assigned_to_type = 'Organization'
            AND tasks.assigned_to_id = '#{parent.id.to_i}'
          GROUP BY
              versions.item_id, versions.item_type
        ), imr_version_agg AS (SELECT
              versions.item_id,
              versions.item_type,
              STRING_AGG(versions.object, '|||' ORDER BY versions.id) AS object_array,
              STRING_AGG(versions.object_changes, '|||' ORDER BY versions.id) AS object_changes_array
          FROM
              versions
          INNER JOIN issue_modification_requests ON issue_modification_requests.id = versions.item_id
          WHERE versions.item_type = 'IssueModificationRequest'
          GROUP BY
              versions.item_id, versions.item_type
        ), imr_distinct AS (
            SELECT DISTINCT ON (imr_cte.id)
                imr_cte.id,
                imr_cte.decided_at,
                imr_cte.created_at,
                imr_cte.decision_review_type,
                imr_cte.decision_review_id,
                imr_cte.status,
                imr_cte.updated_at
            FROM issue_modification_requests imr_cte
        ), imr_lead_decided AS (
            SELECT id,
                  decision_review_id,
                  LEAD(
                    CASE
                      WHEN status = 'cancelled' THEN updated_at
                      ELSE decided_at
                    END,
                    1,
                    '9999-12-31 23:59:59' -- Fake value to indicate out of bounds
                  ) OVER (PARTITION BY decision_review_id, decision_review_type ORDER BY decided_at, created_at DESC) AS next_decided_or_cancelled_at
            FROM imr_distinct
        ), imr_lead_created AS (
            SELECT id,
                LEAD(created_at, 1, '9999-12-31 23:59:59') OVER (PARTITION BY decision_review_id, decision_review_type ORDER BY created_at ASC) AS next_created_at
            FROM imr_distinct
        )
        SELECT tasks.id AS task_id,
          check_imr_current_status.is_assigned_present,
          tasks.status AS task_status,
          request_issues.id AS request_issue_id,
          request_issues_updates.created_at AS request_issue_update_time, decision_issues.description AS decision_description,
          request_issues.benefit_type AS request_issue_benefit_type, request_issues_updates.id AS request_issue_update_id,
          request_issues.created_at AS request_issue_created_at, request_decision_issues.created_at AS request_decision_created_at,
          intakes.completed_at AS intake_completed_at, update_users.full_name AS update_user_name, tasks.created_at AS task_created_at,
          intake_users.full_name AS intake_user_name, update_users.station_id AS update_user_station_id, tasks.closed_at AS task_closed_at,
          intake_users.station_id AS intake_user_station_id, decision_issues.created_at AS decision_created_at,
          COALESCE(decision_users.station_id, decision_users_completed_by.station_id) AS decision_user_station_id,
          COALESCE(decision_users.full_name, decision_users_completed_by.full_name) AS decision_user_name,
          COALESCE(decision_users.css_id, decision_users_completed_by.css_id) AS decision_user_css_id,
          intake_users.css_id AS intake_user_css_id, update_users.css_id AS update_user_css_id,
          request_issues_updates.before_request_issue_ids, request_issues_updates.after_request_issue_ids,
          request_issues_updates.withdrawn_request_issue_ids, request_issues_updates.edited_request_issue_ids,
          decision_issues.caseflow_decision_date, request_issues.decision_date_added_at,
          tasks.appeal_type, tasks.appeal_id, request_issues.nonrating_issue_category, request_issues.nonrating_issue_description,
          request_issues.decision_date, decision_issues.disposition, tasks.assigned_at, request_issues.unidentified_issue_text,
          request_decision_issues.decision_issue_id, request_issues.closed_at AS request_issue_closed_at,
          tv.object_changes_array AS task_versions, (#{current_timestamp}::date - tasks.assigned_at::date) AS days_waiting,
          COALESCE(intakes.veteran_file_number, higher_level_reviews.veteran_file_number) AS veteran_file_number,
          COALESCE(
            NULLIF(CONCAT(unrecognized_party_details.name, ' ', unrecognized_party_details.last_name), ' '),
            NULLIF(CONCAT(people.first_name, ' ', people.last_name), ' '),
            bgs_attorneys.name
          ) AS claimant_name,
          'HigherLevelReview' AS type_classifier,
          imr.id AS issue_modification_request_id,
          imr.nonrating_issue_category AS requested_issue_type,
          imr.nonrating_issue_description As requested_issue_description,
          imr.remove_original_issue,
          imr.request_reason AS modification_request_reason,
          imr.decision_date AS requested_decision_date,
          imr.request_type AS request_type,
          imr.status AS issue_modification_request_status,
          imr.decision_reason AS decision_reason,
          imr.decider_id decider_id,
          imr.requestor_id as requestor_id,
          CASE WHEN imr.status = 'cancelled' THEN imr.updated_at ELSE imr.decided_at END AS decided_at,
          imr.created_at AS issue_modification_request_created_at,
          imr.updated_at AS issue_modification_request_updated_at,
          imr.edited_at AS issue_modification_request_edited_at,
          imr.withdrawal_date AS issue_modification_request_withdrawal_date,
          imr.decision_review_id AS decision_review_id,
          imr.decision_review_type AS decision_review_type,
          requestor.full_name AS requestor,
          requestor.station_id AS requestor_station_id,
          requestor.css_id AS requestor_css_id,
          decider.full_name AS decider,
          decider.station_id AS decider_station_id,
          decider.css_id AS decider_css_id,
          itv.object_changes_array AS imr_versions,
          LAG(imr.created_at, 1) OVER (PARTITION BY tasks.id, imr.decision_review_id, imr.decision_review_type ORDER BY imr.created_at) AS previous_imr_created_at,
          LAG(CASE WHEN imr.status = 'cancelled' THEN imr.updated_at ELSE imr.decided_at END) OVER (PARTITION BY tasks.id, imr.decision_review_id, imr.decision_review_type ORDER BY CASE WHEN imr.status = 'cancelled' THEN imr.updated_at ELSE imr.decided_at END) AS previous_imr_decided_at,
          itv.object_array as previous_state_array,
          imr_lead_decided.next_decided_or_cancelled_at,
          imr_lead_created.next_created_at
        FROM tasks
        INNER JOIN request_issues ON request_issues.decision_review_type = tasks.appeal_type
        AND request_issues.decision_review_id = tasks.appeal_id
        INNER JOIN higher_level_reviews ON tasks.appeal_type = 'HigherLevelReview'
        AND tasks.appeal_id = higher_level_reviews.id
        INNER JOIN intakes ON tasks.appeal_type = intakes.detail_type
        AND intakes.detail_id = tasks.appeal_id
        LEFT JOIN request_issues_updates ON request_issues_updates.review_type = tasks.appeal_type
        AND request_issues_updates.review_id = tasks.appeal_id
        LEFT JOIN LATERAL (
          SELECT *
          FROM issue_modification_requests imr
          WHERE imr.decision_review_id = tasks.appeal_id
            AND imr.decision_review_type = 'HigherLevelReview'
            AND (
                imr.request_issue_id = request_issues.id
                OR imr.request_type = 'addition'
            )
        ) imr ON true
        LEFT JOIN imr_lead_decided ON imr_lead_decided.id = imr.id
        LEFT JOIN imr_lead_created ON imr_lead_created.id = imr.id
        LEFT JOIN request_decision_issues ON request_decision_issues.request_issue_id = request_issues.id
        LEFT JOIN decision_issues ON decision_issues.decision_review_id = tasks.appeal_id
        AND decision_issues.decision_review_type = tasks.appeal_type AND decision_issues.id = request_decision_issues.decision_issue_id
        LEFT JOIN claimants ON claimants.decision_review_id = tasks.appeal_id
        AND claimants.decision_review_type = tasks.appeal_type
        LEFT JOIN versions_agg tv ON tv.item_type = 'Task' AND tv.item_id = tasks.id
        LEFT JOIN people ON claimants.participant_id = people.participant_id
        LEFT JOIN bgs_attorneys ON claimants.participant_id = bgs_attorneys.participant_id
        LEFT JOIN unrecognized_appellants ON claimants.id = unrecognized_appellants.claimant_id
        LEFT JOIN unrecognized_party_details ON unrecognized_appellants.unrecognized_party_detail_id = unrecognized_party_details.id
        LEFT JOIN users intake_users ON intakes.user_id = intake_users.id
        LEFT JOIN users update_users ON request_issues_updates.user_id = update_users.id
        LEFT JOIN users decision_users ON decision_users.id = tv.version_closed_by_id::int
        LEFT JOIN users decision_users_completed_by ON decision_users_completed_by.id = tasks.completed_by_id
        LEFT JOIN users requestor ON imr.requestor_id = requestor.id
        LEFT JOIN users decider ON imr.decider_id = decider.id
        LEFT JOIN imr_version_agg itv ON itv.item_type = 'IssueModificationRequest' AND itv.item_id = imr.id
        LEFT JOIN LATERAL (
             SELECT CASE
           WHEN EXISTS (
             SELECT 1
             FROM issue_modification_requests imr
             WHERE imr.decision_review_id = request_issues.decision_review_id
             AND imr.decision_review_type = 'HigherLevelReview'
               AND imr.status = 'assigned'
           ) THEN true
           ELSE false
       END AS is_assigned_present
         ) check_imr_current_status on true
        WHERE tasks.type = 'DecisionReviewTask'
        AND tasks.assigned_to_type = 'Organization'
        AND tasks.assigned_to_id = '#{parent.id.to_i}'
        #{sanitized_filters}
      UNION ALL
      SELECT tasks.id AS task_id, check_imr_current_status.is_assigned_present, tasks.status AS task_status, request_issues.id AS request_issue_id,
        request_issues_updates.created_at AS request_issue_update_time, decision_issues.description AS decision_description,
        request_issues.benefit_type AS request_issue_benefit_type, request_issues_updates.id AS request_issue_update_id,
        request_issues.created_at AS request_issue_created_at, request_decision_issues.created_at AS request_decision_created_at,
        intakes.completed_at AS intake_completed_at, update_users.full_name AS update_user_name, tasks.created_at AS task_created_at,
        intake_users.full_name AS intake_user_name, update_users.station_id AS update_user_station_id, tasks.closed_at AS task_closed_at,
        intake_users.station_id AS intake_user_station_id, decision_issues.created_at AS decision_created_at,
        COALESCE(decision_users.station_id, decision_users_completed_by.station_id) AS decision_user_station_id,
        COALESCE(decision_users.full_name, decision_users_completed_by.full_name) AS decision_user_name,
        COALESCE(decision_users.css_id, decision_users_completed_by.css_id) AS decision_user_css_id,
        intake_users.css_id AS intake_user_css_id, update_users.css_id AS update_user_css_id,
        request_issues_updates.before_request_issue_ids, request_issues_updates.after_request_issue_ids,
        request_issues_updates.withdrawn_request_issue_ids, request_issues_updates.edited_request_issue_ids,
        decision_issues.caseflow_decision_date, request_issues.decision_date_added_at,
        tasks.appeal_type, tasks.appeal_id, request_issues.nonrating_issue_category, request_issues.nonrating_issue_description,
        request_issues.decision_date, decision_issues.disposition, tasks.assigned_at, request_issues.unidentified_issue_text,
        request_decision_issues.decision_issue_id, request_issues.closed_at AS request_issue_closed_at,
        tv.object_changes_array AS task_versions, (#{current_timestamp}::date - tasks.assigned_at::date) AS days_waiting,
        COALESCE(intakes.veteran_file_number, supplemental_claims.veteran_file_number) AS veteran_file_number,
        COALESCE(
          NULLIF(CONCAT(unrecognized_party_details.name, ' ', unrecognized_party_details.last_name), ' '),
          NULLIF(CONCAT(people.first_name, ' ', people.last_name), ' '),
          bgs_attorneys.name
        ) AS claimant_name,
         supplemental_claims.type AS type_classifier,
         imr.id AS issue_modification_request_id,
         imr.nonrating_issue_category AS requested_issue_type,
         imr.nonrating_issue_description As requested_issue_description,
         imr.remove_original_issue,
         imr.request_reason AS modification_request_reason,
         imr.decision_date AS requested_decision_date,
         imr.request_type AS request_type,
         imr.status AS issue_modification_request_status,
         imr.decision_reason AS decision_reason,
         imr.decider_id AS decider_id,
         imr.requestor_id AS requestor_id,
         CASE WHEN imr.status = 'cancelled' THEN imr.updated_at ELSE imr.decided_at END AS decided_at,
         imr.created_at AS issue_modification_request_created_at,
         imr.updated_at  AS issue_modification_request_updated_at,
         imr.edited_at AS issue_modification_request_edited_at,
         imr.withdrawal_date  AS issue_modification_request_withdrawal_date,
         imr.decision_review_id  AS decision_review_id,
         imr.decision_review_type AS decision_review_type,
         requestor.full_name AS requestor,
         requestor.station_id AS requestor_station_id,
         requestor.css_id AS requestor_css_id,
         decider.full_name AS decider,
         decider.station_id AS decider_station_id,
         decider.css_id AS decider_css_id,
         itv.object_changes_array AS imr_versions,
         LAG(imr.created_at, 1) OVER (PARTITION BY tasks.id, imr.decision_review_id, imr.decision_review_type ORDER BY imr.created_at) AS previous_imr_created_at,
         LAG(CASE WHEN imr.status = 'cancelled' THEN imr.updated_at ELSE imr.decided_at END) OVER (PARTITION BY tasks.id, imr.decision_review_id, imr.decision_review_type ORDER BY CASE WHEN imr.status = 'cancelled' THEN imr.updated_at ELSE imr.decided_at END) AS previous_imr_decided_at,
         itv.object_array as previous_state_array,
         imr_lead_decided.next_decided_or_cancelled_at,
         imr_lead_created.next_created_at
      FROM tasks
      INNER JOIN request_issues ON request_issues.decision_review_type = tasks.appeal_type
      AND request_issues.decision_review_id = tasks.appeal_id
      INNER JOIN supplemental_claims ON tasks.appeal_type = 'SupplementalClaim'
      AND tasks.appeal_id = supplemental_claims.id
      LEFT JOIN intakes ON tasks.appeal_type = intakes.detail_type
      AND intakes.detail_id = tasks.appeal_id
      LEFT JOIN request_issues_updates ON request_issues_updates.review_type = tasks.appeal_type
      AND request_issues_updates.review_id = tasks.appeal_id
      LEFT JOIN LATERAL (
        SELECT *
        FROM issue_modification_requests imr
        WHERE imr.decision_review_id = tasks.appeal_id
          AND imr.decision_review_type = 'SupplementalClaim'
          AND (
              imr.request_issue_id = request_issues.id
              OR imr.request_type = 'addition'
          )
      ) imr ON true
      LEFT JOIN imr_lead_decided ON imr_lead_decided.id = imr.id
      LEFT JOIN imr_lead_created ON imr_lead_created.id = imr.id
      LEFT JOIN request_decision_issues ON request_decision_issues.request_issue_id = request_issues.id
      LEFT JOIN decision_issues ON decision_issues.decision_review_id = tasks.appeal_id
      AND decision_issues.decision_review_type = tasks.appeal_type AND decision_issues.id = request_decision_issues.decision_issue_id
      LEFT JOIN claimants ON claimants.decision_review_id = tasks.appeal_id
      AND claimants.decision_review_type = tasks.appeal_type
      LEFT JOIN versions_agg tv ON tv.item_type = 'Task' AND tv.item_id = tasks.id
      LEFT JOIN people ON claimants.participant_id = people.participant_id
      LEFT JOIN bgs_attorneys ON claimants.participant_id = bgs_attorneys.participant_id
      LEFT JOIN unrecognized_appellants ON claimants.id = unrecognized_appellants.claimant_id
      LEFT JOIN unrecognized_party_details ON unrecognized_appellants.unrecognized_party_detail_id = unrecognized_party_details.id
      LEFT JOIN users intake_users ON intakes.user_id = intake_users.id
      LEFT JOIN users update_users ON request_issues_updates.user_id = update_users.id
      LEFT JOIN users decision_users ON decision_users.id = tv.version_closed_by_id::int
      LEFT JOIN users decision_users_completed_by ON decision_users_completed_by.id = tasks.completed_by_id
      LEFT JOIN users requestor ON imr.requestor_id  = requestor.id
      LEFT JOIN users decider ON  imr.decider_id  = decider.id
      LEFT JOIN imr_version_agg itv ON itv.item_type = 'IssueModificationRequest' AND itv.item_id = imr.id
      LEFT JOIN LATERAL (
             SELECT CASE
           WHEN EXISTS (
             SELECT 1
             FROM issue_modification_requests imr
             WHERE imr.decision_review_id = request_issues.decision_review_id
             AND imr.decision_review_type = 'SupplementalClaim'
               AND imr.status = 'assigned'
           ) THEN true
           ELSE false
       END AS is_assigned_present
         ) check_imr_current_status on true
      WHERE tasks.type = 'DecisionReviewTask'
      AND tasks.assigned_to_type = 'Organization'
      AND tasks.assigned_to_id = '#{parent.id.to_i}'
      #{sanitized_filters}
      #{sc_type_clauses}
      SQL

      ActiveRecord::Base.transaction do
        # increase the timeout for the transaction because the query more than the default 30 seconds
        ActiveRecord::Base.connection.execute "SET LOCAL statement_timeout = 180000"
        ActiveRecord::Base.connection.execute change_history_sql_block
      end
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
        task_specific_status_filter
      else
        " AND tasks.status IN ('assigned', 'in_progress', 'on_hold', 'completed', 'cancelled') "
      end
    end

    def task_specific_status_filter
      if query_params[:task_status].include?("pending")
        task_status_pending_filter
      else
        task_status_without_pending_filter
      end
    end

    def task_status_pending_filter
      <<-SQL
       AND (
        (imr.id IS NOT NULL AND imr.status = 'assigned')
        OR #{where_clause_from_array(Task, :status, query_params[:task_status].uniq).to_sql}
       )
      SQL
    end

    def task_status_without_pending_filter
      <<-SQL
         AND NOT EXISTS(
             SELECT decision_review_id FROM issue_modification_requests WHERE
             issue_modification_requests.status = 'assigned'
             AND issue_modification_requests.decision_review_id = tasks.appeal_id
             AND tasks.appeal_type = issue_modification_requests.decision_review_type)
        AND #{where_clause_from_array(Task, :status, query_params[:task_status].uniq).to_sql}
      SQL
    end

    def claim_type_filter
      if query_params[:claim_type].present?
        temp_claim_types = query_params[:claim_type].dup

        if query_params[:claim_type].include?(Remand.name)
          temp_claim_types.push "SupplementalClaim"
        end

        " AND #{where_clause_from_array(Task, :appeal_type, temp_claim_types).to_sql} "
      else
        " AND tasks.appeal_type IN ('HigherLevelReview', 'SupplementalClaim' ) "
      end
    end

    def sc_type_filter
      if query_params[:claim_type].present?
        if query_params[:claim_type].include?(Remand.name) || query_params[:claim_type].include?(SupplementalClaim.name)
          " AND #{where_clause_from_array(SupplementalClaim, :type, query_params[:claim_type]).to_sql} "
        else
          ""
        end
      else
        ""
      end
    end

    def task_id_filter
      if query_params[:task_id].present?
        " AND #{where_clause_from_array(Task, :id, query_params[:task_id]).to_sql} "
      end
    end

    def dispositions_filter
      if query_params[:dispositions].present?
        disposition_params = query_params[:dispositions] - ["Blank"]
        sql = where_clause_from_array(DecisionIssue, :disposition, disposition_params).to_sql

        if query_params[:dispositions].include?("Blank")
          if disposition_params.empty?
            " AND decision_issues.disposition IS NULL "
          else
            " AND (#{sql} OR decision_issues.disposition IS NULL) "
          end
        else
          " AND #{sql} "
        end
      end
    end

    def issue_types_filter
      if query_params[:issue_types].present?
        sql = where_clause_from_array(RequestIssue, :nonrating_issue_category, query_params[:issue_types]).to_sql
        " AND #{sql} "
      end
    end

    def days_waiting_filter
      current_timestamp = ActiveRecord::Base.connection.quote(Time.zone.now)
      if query_params[:days_waiting].present?
        number_of_days = query_params[:days_waiting][:number_of_days]
        operator = query_params[:days_waiting][:operator]
        case operator
        when ">", "<", "="
          <<-SQL
            AND (#{current_timestamp}::date - tasks.assigned_at::date)::integer #{operator} '#{number_of_days.to_i}'
          SQL
        when "between"
          end_days = query_params[:days_waiting][:end_days]
          <<-SQL
            AND (#{current_timestamp}::date - tasks.assigned_at::date)::integer BETWEEN '#{number_of_days.to_i}' AND '#{end_days.to_i}'
            AND (#{current_timestamp}::date - tasks.assigned_at::date)::integer BETWEEN '#{number_of_days.to_i}' AND '#{end_days.to_i}'
          SQL
        end
      end
    end

    def station_id_filter
      if query_params[:facilities].present?
        conditions = USER_TABLE_ALIASES.map do |alias_name|
          User.arel_table.alias(alias_name)[:station_id].in(query_params[:facilities]).to_sql
        end

        <<-SQL
          AND
          (
            #{conditions.join(' OR ')}
          )
        SQL
      end
    end

    def user_css_id_filter
      if query_params[:personnel].present?
        conditions = USER_TABLE_ALIASES.map do |alias_name|
          User.arel_table.alias(alias_name)[:css_id].in(query_params[:personnel]).to_sql
        end

        <<-SQL
          AND
          (
            #{conditions.join(' OR ')}
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
        pending_issue_count,
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
      # This needs a distinct count because the query returns 1 row for each request issue and
      # now it can return 1 additional row for each issue modification request with a duplicated request issue.id
      "COUNT(DISTINCT request_issues.id) AS issue_count"
    end

    def pending_issue_count
      # Issue modification request count alias for sorting and serialization
      "COUNT(DISTINCT issue_modification_requests.id) AS pending_issue_count"
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

    def issue_modification_request_join
      "LEFT JOIN issue_modification_requests on issue_modification_requests.decision_review_id = tasks.appeal_id
        AND issue_modification_requests.decision_review_type = tasks.appeal_type"
    end

    def issue_modification_request_filter
      if query_type == :pending
        "issue_modification_requests.id IS NOT NULL
          AND issue_modification_requests.status = 'assigned'"
      else
        "NOT EXISTS(
          SELECT decision_review_id FROM issue_modification_requests WHERE
          issue_modification_requests.status = 'assigned'
          AND issue_modification_requests.decision_review_id = tasks.appeal_id
          AND tasks.appeal_type = issue_modification_requests.decision_review_type)"
      end
    end

    def union_query_join_clauses
      [
        veterans_join,
        claimants_join,
        people_join,
        unrecognized_appellants_join,
        party_details_join,
        bgs_attorneys_join,
        issue_modification_request_join
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
      "veteran_is_not_claimant, bgs_attorneys.name, sub_type"
    end

    # Uses an array to insert the searched text into all of the searchable fields since it's the same text for all
    def search_values
      searching_text = "%#{query_params[:search_query]}%"
      Array.new(number_of_search_fields, searching_text)
    end

    def higher_level_reviews_on_request_issues
      sub_type_alias = "'HigherLevelReview' AS sub_type"
      decision_reviews_on_request_issues({ higher_level_review: :request_issues }, sub_type_alias)
    end

    def supplemental_claims_on_request_issues
      sub_type_alias = "supplemental_claims.type AS sub_type"
      decision_reviews_on_request_issues({ supplemental_claim: :request_issues }, sub_type_alias)
    end

    def appeals_on_request_issues
      sub_type_alias = "'Appeal' as sub_type"
      decision_reviews_on_request_issues({ ama_appeal: :request_issues }, sub_type_alias)
    end

    # Specific case for BoardEffectuationGrantTasks to include them in the result set
    # if the :board_grant_effectuation_task FeatureToggle is enabled for the current user.
    def board_grant_effectuation_tasks
      sub_type_alias = "'Appeal' as sub_type"
      decision_reviews_on_request_issues(board_grant_effectuation_task_appeals_requests_join,
                                         sub_type_alias,
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

    def decision_reviews_on_request_issues(join_constraint, subclass_type_alias, where_constraints = query_constraints)
      Task.select(union_select_statements.append(subclass_type_alias))
        .send(parent.tasks_query_type[query_type])
        .joins(join_constraint)
        .joins(*union_query_join_clauses)
        .where(where_constraints)
        .where(search_all_clause, *search_values)
        .where(issue_type_filter_predicate(query_params[:filters]))
        .where(issue_modification_request_filter)
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
        pending: {
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
