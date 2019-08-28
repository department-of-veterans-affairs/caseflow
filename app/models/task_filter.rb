# frozen_string_literal: true

class TaskFilter
  include ActiveModel::Model

  validate :filter_params_is_array
  validate :tasks_type_is_valid

  attr_accessor :filter_params, :tasks

  def initialize(args)
    super

    @filters_params ||= []
    @tasks ||= Task.none

    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  def filtered_tasks
    where_clause.empty? ? tasks : tasks.joins(CachedAppeal.left_join_from_tasks_clause).where(*where_clause)
  end

  # filter_params = ["col=docketNumberColumn&val=legacy,evidence_submission", "col=taskColumn&val=TranslationTask"]
  #
  # [
  #   "cached_appeals_attributes.docket_type IN (?) AND tasks.type in (?)",
  #   ["legacy", "evidence_submission"],
  #   ["TranslationTask"]
  # ]
  def where_clause
    return [] if filter_params.empty?

    filters = filter_params.map { |filter_string| QueueFilterParameter.from_string(filter_string) }

    where_string = filters.map { |filter| "#{table_column_from_name(filter.column)} IN (?)" }.join(" AND ")
    where_arguments = filters.map(&:values)

    [where_string] + where_arguments
  end

  private

  def table_column_from_name(column_name)
    case column_name
    when Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN
      "tasks.type"
    when Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN
      "cached_appeal_attributes.closest_regional_office_city"
    # TODO: The following columns are not yet implemented.
    # when Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN
    #   "cached_appeal_attributes.appeal_type"
    # TODO: I think this constant may be incorrectly named.
    # when Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN
    #   "cached_appeal_attributes.docket_type"
    # when Constants.QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN
    #   "???"
    else
      fail(Caseflow::Error::InvalidTaskTableColumnFilter, column: column_name)
    end
  end

  def filter_params_is_array
    errors.add(:filter_params, "must be an array") unless filter_params&.is_a?(Array)
  end

  def tasks_type_is_valid
    errors.add(:tasks, COPY::INVALID_TASKS_ARGUMENT) unless tasks.is_a?(ActiveRecord::Relation)
  end
end
