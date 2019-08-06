# frozen_string_literal: true

class QueueWhereClauseArgumentsFactory
  include ActiveModel::Model

  validate :filter_params_is_array

  attr_accessor :filter_params

  def initialize(args)
    super
    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  # filter_params = ["col=docketNumberColumn&val=legacy,evidence_submission", "col=taskColumn&val=TranslationTask"]
  #
  # [
  #   "cached_appeals_attributes.docket_type IN (?) AND tasks.type in (?)",
  #   ["legacy", "evidence_submission"],
  #   ["TranslationTask"]
  # ]
  def arguments
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
    # TODO: The following columns are not yet implemented.
    # when Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN
    #   "cached_appeals_attributes.appeal_type"
    # when Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN
    #   "cached_appeals_attributes.regional_office"
    # TODO: I think this constant may be incorrectly named.
    # when Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN
    #   "cached_appeals_attributes.docket_type"
    # when Constants.QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN
    #   "???"
    else
      fail(Caseflow::Error::InvalidTaskTableColumnFilter, column: column_name)
    end
  end

  def filter_params_is_array
    errors.add(:filter_params, "must be an array") unless filter_params&.is_a?(Array)
  end
end
