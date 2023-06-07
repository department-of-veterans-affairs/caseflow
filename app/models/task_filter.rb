# frozen_string_literal: true

class TaskFilter
  include ActiveModel::Model

  validate :filter_params_is_array
  validate :tasks_type_is_valid

  attr_accessor :filter_params, :tasks

  class << self
    def where_string_from_filters(filters)
      filters.map do |filter|
        if filter.values.present?
          create_where_clause(filter)
        end
      end.compact.join(" AND ")
    end

    private

    def create_where_clause(filter)
      # Default clause is an IN. The values are placed later in the query in the where_clause method
      clause = "#{table_column_from_name(filter.column)} IN (?)"
      clause = extract_former_travel_clause(filter, clause) if former_travel_filter?(filter)
      clause = extract_aod_clause(filter, clause) if aod_filter?(filter)
      clause = build_issue_type_clause(filter) if issue_types_filter?(filter)
      clause
    end

    # Filter is an object not an instance of hash but rubocop is confused by .values
    # rubocop:disable Performance/InefficientHashSearch
    def former_travel_filter?(filter)
      filter.column == Constants.QUEUE_CONFIG.HEARING_REQUEST_TYPE_COLUMN_NAME &&
        filter.values.include?(Constants.QUEUE_CONFIG.FILTER_OPTIONS.IS_FORMER_TRAVEL.key)
    end

    def aod_filter?(filter)
      filter.column == Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name &&
        filter.values.include?(Constants.QUEUE_CONFIG.FILTER_OPTIONS.IS_AOD.key)
    end
    # rubocop:enable Performance/InefficientHashSearch

    def issue_types_filter?(filter)
      filter.column == Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name
    end

    def extract_former_travel_clause(filter, orig_clause)
      is_former_travel_clause = "cached_appeal_attributes.former_travel = true"
      (filter.values.size == 1) ? is_former_travel_clause : "(#{orig_clause} OR #{is_former_travel_clause})"
    end

    def extract_aod_clause(filter, orig_clause)
      filter.values.delete(Constants.QUEUE_CONFIG.FILTER_OPTIONS.IS_AOD.key)
      is_aod_clause = "cached_appeal_attributes.is_aod = true"
      filter.values.empty? ? is_aod_clause : "(#{orig_clause} OR #{is_aod_clause})"
    end

    # Filter: "filter"=>["col=issueTypesColumn&val=Beneficiary%2520Travel"]
    # Resulting SQL: "POSITION('Beneficiary Travel' IN cached_appeal_attributes.issue_types) > 0"
    def build_issue_type_clause(filter)
      filter_selections = filter.values
      # Shorthand way of parsing the first value differently than the rest
      first_filter_value, *remaining_filters = filter_selections
      where_clauses = []
      where_clauses << issue_type_where_clause(first_filter_value, filter)

      remaining_filters.each do |filter_value|
        where_clauses << "OR #{issue_type_where_clause(filter_value, filter)}"
      end

      # If you don't include a param insert (?) it will ignore it later in the where_clause method
      # Which is what we want, since we handle it here instead of in the where clause method
      # because the position SQL function does not accept the same paramaters as IN does
      # Finally wrap the joins in parentheses to preserve logical and/or ordering between other filters
      "(#{where_clauses.join(' ')})"
    end

    def issue_type_where_clause(filter_value, filter)
      if filter_value == Constants.QUEUE_CONFIG.BLANK_FILTER_KEY_VALUE
        "#{table_column_from_name(filter.column)} IS NULL OR #{table_column_from_name(filter.column)} = '' "
      # Check the values against all the possible ISSUE_CATEGORIES as a form of sanitation and value validation
      elsif Constants.ISSUE_CATEGORIES.to_h.values.any? { |value| value.include?(filter_value) }
        "'#{filter_value}' = ANY (string_to_array(cached_appeal_attributes.issue_types, ',')) "
      else
        # Default to returning no tasks if the value was somehow not valid. Log an error but continue
        Rails.logger.error("User somehow filtered on an invalid issue category **#{filter_value}**")
        "1=0 "
      end
    end

    COLUMN_MAPPING = {
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name => "tasks.type",
      Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name => "cached_appeal_attributes.closest_regional_office_city",
      Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name => "cached_appeal_attributes.docket_type",
      Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name => "cached_appeal_attributes.case_type",
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name => "assignees.display_name",
      Constants.QUEUE_CONFIG.POWER_OF_ATTORNEY_COLUMN_NAME => "cached_appeal_attributes.power_of_attorney_name",
      Constants.QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN_NAME =>
        "cached_appeal_attributes.suggested_hearing_location",
      Constants.QUEUE_CONFIG.HEARING_REQUEST_TYPE_COLUMN_NAME => "cached_appeal_attributes.hearing_request_type",
      Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name => "cached_appeal_attributes.issue_types"
    }.freeze

    def table_column_from_name(column_name)
      column_name = COLUMN_MAPPING[column_name]
      column_name || fail(Caseflow::Error::InvalidTaskTableColumnFilter, column: column_name)
    end
  end

  def initialize(args)
    super

    @filters_params ||= []
    @tasks ||= Task.none

    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  def filtered_tasks
    return tasks if where_clause.empty?

    tasks.with_assignees.with_cached_appeals.where(*where_clause)
  end

  # filter_params = ["col=docketNumberColumn&val=legacy|evidence_submission", "col=taskColumn&val=TranslationTask"]
  #
  # [
  #   "cached_appeals_attributes.docket_type IN (?) AND tasks.type in (?)",
  #   ["legacy", "evidence_submission"],
  #   ["TranslationTask"]
  # ]
  def where_clause
    return [] if filter_params.empty?

    filters = filter_params.map(&QueueFilterParameter.method(:from_string))
    where_string = TaskFilter.where_string_from_filters(filters)
    where_arguments = parse_where_arguments(filters)

    [where_string] + where_arguments
  end

  private

  def filter_params_is_array
    errors.add(:filter_params, "must be an array") unless filter_params&.is_a?(Array)
  end

  def tasks_type_is_valid
    errors.add(:tasks, COPY::INVALID_TASKS_ARGUMENT) unless tasks.is_a?(ActiveRecord::Relation)
  end

  IGNORE_FILTER_PLACEHOLDERS = [
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name
  ].freeze

  def parse_where_arguments(filters)
    # Reject all columns that do not need placeholders in the query.
    # This allows more freedom in building where clauses that might use other statements instead of just IN (?)
    # Queries build this way need their own input sanitization since they will not use the standard rails placeholders
    where_filters = filters.reject { |filter_param| IGNORE_FILTER_PLACEHOLDERS.include?(filter_param.try(:column)) }

    # Reject all arguments that are empty and return the remaining values
    where_filters.map(&:values).reject(&:empty?)
  end
end
