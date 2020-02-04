# frozen_string_literal: true

##
# A version of QueueTab except it accounts only for Assign Hearings Table.
# Acts as a general tab for the two tabs for the table: amaAssignHearingTab,
# and legacyAssignHearingTab which are paginated.

class AssignHearing
  attr_accessor :regional_office_key, :appeal_type

  def initialize(appeal_type:, regional_office_key:)
    @appeal_type = appeal_type
    @regional_office_key = regional_office_key
  end

  def tasks
    ScheduleHearingTask
      .includes(*task_includes)
      .active
      .where(appeal_type: appeal_type)
      .joins(CachedAppeal.left_join_from_tasks_clause)
      .where("cached_appeal_attributes.closest_regional_office_key = ?", regional_office_key)
  end

  def to_hash
    { columns: columns }
  end

  # return filter options for columns
  def columns
    [
      {
        name: Constants.QUEUE_CONFIG.POWER_OF_ATTORNEY_COLUMN_NAME,
        filter_options: power_of_attorney_name_options(tasks)
      },
      {
        name: Constants.QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN_NAME,
        filter_options: suggested_location_options(tasks)
      }
    ]
  end

  # same function from queue_column
  # rubocop:disable Style/FormatStringToken
  def self.format_option_label(label, count)
    label ||= COPY::NULL_FILTER_LABEL
    format("%s (%d)", label, count)
  end
  # rubocop:enable Style/FormatStringToken

  # same function from queue_column
  def self.filter_option_hash(value, label)
    value ||= COPY::NULL_FILTER_LABEL
    # Double encode the values here since we un-encode them twice in QueueFilterParameter. Once when parsing the query
    # and again when unpacking the values of the selected filters into an array.
    { value: URI.escape(URI.escape(value)), displayText: label }
  end

  def power_of_attorney_name_options(tasks)
    tasks.joins(CachedAppeal.left_join_from_tasks_clause)
      .group(:power_of_attorney_name).count.each_pair.map do |option, count|
      label = self.class.format_option_label(option, count)
      self.class.filter_option_hash(option, label)
    end
  end

  def suggested_location_options(tasks)
    tasks.joins(CachedAppeal.left_join_from_tasks_clause)
      .group(:suggested_hearing_location).count.each_pair.map do |option, count|
      label = self.class.format_option_label(option, count)
      self.class.filter_option_hash(option, label)
    end
  end

  def task_includes
    [
      { appeal: [:available_hearing_locations, :claimants] },
      { attorney_case_reviews: [:attorney] },
      :assigned_by,
      :assigned_to,
      :children,
      :parent
    ]
  end
end
