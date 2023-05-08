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
      clause = "#{table_column_from_name(filter.column)} IN (?)"
      filter_selections = filter.values
      if filter.column == Constants.QUEUE_CONFIG.HEARING_REQUEST_TYPE_COLUMN_NAME &&
         filter_selections.include?(Constants.QUEUE_CONFIG.FILTER_OPTIONS.IS_FORMER_TRAVEL.key)
        clause = extract_former_travel_clause(filter, clause)
      end
      if filter.column == Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name &&
         filter_selections.include?(Constants.QUEUE_CONFIG.FILTER_OPTIONS.IS_AOD.key)
        clause = extract_aod_clause(filter, clause)
      end
      if filter.column == Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name
        # puts "---------------------IN MY crappy block-------------------------------------"
        # puts filter_selections.inspect
        # Shorthand way of parsing the first value differently than the rest
        first_filter_value, *remaining_filters = filter_selections
        where_clauses = []
        where_clauses << "POSITION('#{first_filter_value}' IN #{table_column_from_name(filter.column)}) > 0"

        remaining_filters.each do |filter_value|
          where_clauses << "OR POSITION('#{filter_value}' IN #{table_column_from_name(filter.column)}) > 0"
        end

        # If you don't include a param insert (?) it will ignore it later in the where_clause method
        # Which is what we want since we handle it here instead of in the where clause method
        # becausse the position SQL function doesn't work like IN does
        clause = where_clauses.join(" ")
        # clause = "POSITION((?) IN #{table_column_from_name(filter.column)}) > 0"
        # puts clause.inspect
        # clause
      end
      clause
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

    # rubocop:disable Metrics/CyclomaticComplexity
    def table_column_from_name(column_name)
      case column_name
      when Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name
        "tasks.type"
      when Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name
        "cached_appeal_attributes.closest_regional_office_city"
      when Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name
        "cached_appeal_attributes.docket_type"
      when Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name
        "cached_appeal_attributes.case_type"
      when Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name
        "assignees.display_name"
      when Constants.QUEUE_CONFIG.POWER_OF_ATTORNEY_COLUMN_NAME
        "cached_appeal_attributes.power_of_attorney_name"
      when Constants.QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN_NAME
        "cached_appeal_attributes.suggested_hearing_location"
      when Constants.QUEUE_CONFIG.HEARING_REQUEST_TYPE_COLUMN_NAME
        "cached_appeal_attributes.hearing_request_type"
      when Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name
        "cached_appeal_attributes.issue_types"
      else
        fail(Caseflow::Error::InvalidTaskTableColumnFilter, column: column_name)
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
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
    where_arguments = filters.map(&:values).reject(&:empty?)

    [where_string] + where_arguments
  end

  private

  def filter_params_is_array
    errors.add(:filter_params, "must be an array") unless filter_params&.is_a?(Array)
  end

  def tasks_type_is_valid
    errors.add(:tasks, COPY::INVALID_TASKS_ARGUMENT) unless tasks.is_a?(ActiveRecord::Relation)
  end
end
