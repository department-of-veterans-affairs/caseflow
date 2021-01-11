# frozen_string_literal: true

##
# A version of QueueTab except it accounts only for Assign Hearings Table.
# Acts as a general tab for the two tabs for the table: amaAssignHearingTab,
# and legacyAssignHearingTab which are paginated.

class AssignHearingTab
  include ActiveModel::Model

  attr_accessor :regional_office_key, :appeal_type

  def initialize(appeal_type:, regional_office_key:)
    @appeal_type = appeal_type
    @regional_office_key = regional_office_key
  end

  # return schedule hearing tasks joined with CachedAppeal selected
  # by regional office
  def tasks
    tasks =
      ScheduleHearingTask
        .includes(*task_includes)
        .active
        .with_cached_appeals
        .where(appeal_type: appeal_type)

    @tasks ||=
      if appeal_type == "LegacyAppeal"
        legacy_tasks(tasks)
      else
        ama_tasks(tasks)
      end
  end

  def ama_tasks(tasks)
    case regional_office_key
    when HearingDay::REQUEST_TYPES[:virtual]
      self.class.virtual_hearing_request_tasks(tasks)
    else
      tasks.where("cached_appeal_attributes.closest_regional_office_key = ?", regional_office_key)
    end
  end

  # For legacy appeals, we need to only provide a central office hearing if they explicitly
  # chose one. Likewise, we can't use DC if it's the closest regional office unless they
  # chose a central office hearing.
  def legacy_tasks(tasks)
    central_office_ids = VACOLS::Case.where(bfhr: 1, bfcurloc: "CASEFLOW").pluck(:bfkey)
    central_office_legacy_appeal_ids = LegacyAppeal.where(vacols_id: central_office_ids).pluck(:id)

    case regional_office_key
    when HearingDay::REQUEST_TYPES[:central]
      tasks.where("cached_appeal_attributes.appeal_id IN (?)", central_office_legacy_appeal_ids)
    when HearingDay::REQUEST_TYPES[:virtual]
      self.class.virtual_hearing_request_tasks(tasks)
    else
      tasks_by_ro = tasks.where("cached_appeal_attributes.closest_regional_office_key = ?", regional_office_key)

      # For context: https://github.com/rails/rails/issues/778#issuecomment-432603568
      if central_office_legacy_appeal_ids.empty?
        tasks_by_ro
      else
        tasks_by_ro.where("cached_appeal_attributes.appeal_id NOT IN (?)", central_office_legacy_appeal_ids)
      end
    end
  end

  def self.virtual_hearing_request_tasks(tasks)
    tasks.where(
      "cached_appeal_attributes.hearing_request_type = ?",
      LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[:virtual]
    )
  end

  def to_hash
    { columns: columns }
  end

  # return filter options for columns
  def columns
    [
      {
        name: Constants.QUEUE_CONFIG.POWER_OF_ATTORNEY_COLUMN_NAME,
        filter_options: power_of_attorney_name_options
      },
      {
        name: Constants.QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN_NAME,
        filter_options: suggested_location_options
      },
      {
        name: Constants.QUEUE_CONFIG.HEARING_REQUEST_TYPE_COLUMN_NAME,
        filter_options: hearing_request_type_options
      }
    ]
  end

  # Used with the `TaskColumnSerializer` to serialize only the columns that are
  # in-use by the frontend.
  def self.serialize_columns
    [
      Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
      Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
      Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
      Constants.QUEUE_CONFIG.POWER_OF_ATTORNEY_COLUMN_NAME,
      Constants.QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN_NAME,
      Constants.QUEUE_CONFIG.HEARING_REQUEST_TYPE_COLUMN_NAME
    ]
  end

  def hearing_request_type_options
    options = tasks.with_cached_appeals.group(:hearing_request_type).count.each_pair.map do |option, count|
      label = QueueColumn.format_option_label(option, count)
      QueueColumn.filter_option_hash(option, label)
    end

    former_travel_count = tasks.with_cached_appeals.where("cached_appeal_attributes.former_travel = ?", true).count

    if former_travel_count > 0
      label = QueueColumn.format_option_label(
        Constants.QUEUE_CONFIG.FILTER_OPTIONS.IS_FORMER_TRAVEL.key,
        former_travel_count
      )
      options.append(QueueColumn.filter_option_hash(Constants.QUEUE_CONFIG.FILTER_OPTIONS.IS_FORMER_TRAVEL.key, label))
    end

    options
  end

  def power_of_attorney_name_options
    tasks.with_cached_appeals.group(:power_of_attorney_name).count.each_pair.map do |option, count|
      label = QueueColumn.format_option_label(option, count)
      QueueColumn.filter_option_hash(option, label)
    end
  end

  def suggested_location_options
    tasks.with_cached_appeals.group(:suggested_hearing_location).count.each_pair.map do |option, count|
      label = QueueColumn.format_option_label(option, count)
      QueueColumn.filter_option_hash(option, label)
    end
  end

  def task_includes
    [
      { appeal: [:available_hearing_locations, :claimants] },
      :assigned_by
    ]
  end
end
