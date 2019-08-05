# frozen_string_literal: true

class QueueFilterParameter
  include ActiveModel::Model

  validates :column, presence: true
  validate :values_is_array

  attr_accessor :column, :values

  def initialize(args)
    super
    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  class << self
    def from_string(filter_string)
      # Transform the filter from a string to a hash and create an object from that hash.
      # "col=docketNumberColumn&val=legacy,evidence_submission"
      # ->
      # { "col": "docketNumberColumn", "val": ["legacy", "evidence_submission"] }
      filter_hash = Rack::Utils.parse_query(filter_string)

      new(column: table_column_from_name(filter_hash["col"]), values: filter_hash["val"]&.split(","))
    end

    private

    def table_column_from_name(column_name)
      case column_name
      # TODO: I think this constant may be incorrectly named.
      when Constants.QUEUE_CONFIG.DOCKET_NUMBER_COLUMN
        "cached_appeals_attributes.docket_type"
      when Constants.QUEUE_CONFIG.TASK_TYPE_COLUMN
        "tasks.type"
      # TODO: The following columns are not yet implemented.
      # when Constants.QUEUE_CONFIG.APPEAL_TYPE_COLUMN
      #   "cached_appeals_attributes.appeal_type"
      # when Constants.QUEUE_CONFIG.REGIONAL_OFFICE_COLUMN
      #   "cached_appeals_attributes.regional_office"
      # when Constants.QUEUE_CONFIG.TASK_ASSIGNEE_COLUMN
      #   "???"
      else
        fail(Caseflow::Error::InvalidTaskTableColumnFilter, column: column_name)
      end
    end
  end

  private

  def values_is_array
    errors.add(:values, "must be an array") unless values&.is_a?(Array)
  end
end
