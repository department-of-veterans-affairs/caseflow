# frozen_string_literal: true

class WorkQueue::TaskColumnSerializer
  include FastJsonapi::ObjectSerializer

  def self.serialize_attribute?(params, columns)
    (params[:columns] & columns).any?
  end

  # Used by hasDASRecord()
  attribute :docket_name do |object|
    object.appeal.try(:docket_name)
  end

  attribute :docket_number do |object, params|
    columns = [
      Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name
    ]

    if serialize_attribute?(params, columns)
      object.appeal.try(:docket_number)
    end
  end

  attribute :external_appeal_id do |object, params|
    columns = [
      Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
      Constants.QUEUE_CONFIG.COLUMNS.BADGES.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name
    ]

    if serialize_attribute?(params, columns)
      object.appeal.external_id
    end
  end

  attribute :paper_case do |object, params|
    columns = [
      Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name,
      Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name
    ]

    if serialize_attribute?(params, columns)
      object.appeal.respond_to?(:file_type) ? object.appeal.file_type.eql?("Paper") : nil
    end
  end

  attribute :veteran_full_name do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name]

    if serialize_attribute?(params, columns)
      object.appeal.veteran_full_name
    end
  end

  attribute :veteran_file_number do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name]

    if serialize_attribute?(params, columns)
      object.appeal.veteran_file_number
    end
  end

  attribute :started_at do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name]

    if serialize_attribute?(params, columns)
      object.started_at
    end
  end

  attribute :issue_count do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name]

    if serialize_attribute?(params, columns)
      object.appeal.is_a?(LegacyAppeal) ? object.appeal.undecided_issues.count : object.appeal.number_of_issues
    end
  end

  attribute :aod do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name]

    if serialize_attribute?(params, columns)
      object.appeal.try(:advanced_on_docket?)
    end
  end

  attribute :case_type do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name]

    if serialize_attribute?(params, columns)
      object.appeal.try(:type)
    end
  end

  attribute :label do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name]

    if serialize_attribute?(params, columns)
      object.label
    end
  end

  attribute :placed_on_hold_at do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.DAYS_ON_HOLD.name]

    if serialize_attribute?(params, columns)
      object.calculated_placed_on_hold_at
    end
  end

  attribute :on_hold_duration do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.DAYS_ON_HOLD.name]

    if serialize_attribute?(params, columns)
      object.calculated_on_hold_duration
    end
  end

  attribute :status do |object, params|
    columns = [
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_ON_HOLD.name,
      Constants.QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name
    ]

    if serialize_attribute?(params, columns)
      object.status
    end
  end

  attribute :assigned_at do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name]

    if serialize_attribute?(params, columns)
      object.assigned_at
    end
  end

  attribute :closest_regional_office do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name]

    if serialize_attribute?(params, columns)
      object.appeal.closest_regional_office && RegionalOffice.find!(object.appeal.closest_regional_office)
    end
  end

  attribute :assigned_to do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name]
    assignee = object.assigned_to

    if serialize_attribute?(params, columns)
      {
        css_id: assignee.try(:css_id),
        is_organization: assignee.is_a?(Organization),
        name: assignee.is_a?(Organization) ? assignee.name : assignee.css_id,
        type: assignee.class.name,
        id: assignee.id
      }
    else
      {
        css_id: nil,
        is_organization: nil,
        name: nil,
        type: nil,
        id: nil
      }
    end
  end

  attribute :assigned_by do |object|
    {
      first_name: object.assigned_by_display_name.first,
      last_name: object.assigned_by_display_name.last,
      css_id: object.assigned_by.try(:css_id),
      pg_id: object.assigned_by.try(:id)
    }
  end

  # Used by /hearings/schedule/assign. Not present in the full `task_serializer`.
  attribute :hearing_request_type do |object, params|
    columns = [Constants.QUEUE_CONFIG.HEARING_REQUEST_TYPE_COLUMN_NAME]

    if serialize_attribute?(params, columns)
      # The `hearing_request_type` field doesn't exist on the actual model. This
      # field needs to be added in a select statement and represents the field from
      # the `cached_appeal_attributes` table in `Hearings::ScheduleHearingTasksController`.
      object&.[](:hearing_request_type)
    end
  end

  # Used by /hearings/schedule/assign. Not present in the full `task_serializer`.
  # former_travel technically isn't it's own column, it's part of
  # hearing request type column
  attribute :former_travel do |object, params|
    columns = [Constants.QUEUE_CONFIG.HEARING_REQUEST_TYPE_COLUMN_NAME]

    if serialize_attribute?(params, columns)
      # The `former_travel` field doesn't exist on the actual model. This
      # field needs to be added in a select statement and represents the field from
      # the `cached_appeal_attributes` table in `Hearings::ScheduleHearingTasksController`.
      object&.[](:former_travel)
    end
  end

  # Used by /hearings/schedule/assign. Not present in the full `task_serializer`.
  attribute :power_of_attorney_name do |object, params|
    columns = [Constants.QUEUE_CONFIG.POWER_OF_ATTORNEY_COLUMN_NAME]

    if serialize_attribute?(params, columns)
      # The `power_of_attorney_name` field doesn't exist on the actual model. This
      # field needs to be added in a select statement and represents the field from
      # the `cached_appeal_attributes` table in `Hearings::ScheduleHearingTasksController`.
      object&.[](:power_of_attorney_name)
    end
  end

  # Used by /hearings/schedule/assign. Not present in the full `task_serializer`.
  attribute :suggested_hearing_location do |object, params|
    columns = [Constants.QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN_NAME]

    if serialize_attribute?(params, columns)
      object.appeal.suggested_hearing_location&.to_hash
    end
  end

  attribute :overtime do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.BADGES.name]

    if serialize_attribute?(params, columns)
      object.appeal.try(:overtime?)
    end
  end

  attribute :veteran_appellant_deceased do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.BADGES.name]

    if serialize_attribute?(params, columns)
      begin
        object.appeal.try(:veteran_appellant_deceased?)
      rescue BGS::PowerOfAttorneyFolderDenied => error
        # This is a bit of a leaky abstraction: BGS exceptions are suppressed and logged here so
        # that a single appeal raising this error does not prevent users from loading their queues.
        # This will no longer be necessary when nil date_of_death values, which currently result
        # in flesh BGS calls currently, are cached in Caseflow. Note that other "non-bulk" views,
        # e.g. the case details page, intentionally do not suppress this exception.
        Raven.capture_exception(error)
        nil
      end
    end
  end

  attribute :document_id do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_ID.name]

    if serialize_attribute?(params, columns)
      object.latest_attorney_case_review&.document_id
    end
  end

  attribute :decision_prepared_by do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.DOCUMENT_ID.name]

    if serialize_attribute?(params, columns)
      object.prepared_by_display_name || { first_name: nil, last_name: nil }
    end
  end

  attribute :latest_informal_hearing_presentation_task do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name, Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name]

    if serialize_attribute?(params, columns)
      task = object.appeal.latest_informal_hearing_presentation_task

      task ? { requested_at: task.assigned_at, received_at: task.closed_at } : {}
    end
  end

  # UNUSED

  attribute :assignee_name do
    nil
  end

  attribute :is_legacy do
    nil
  end

  attribute :type do
    nil
  end

  attribute :appeal_id do
    nil
  end

  attribute :created_at do
    nil
  end

  attribute :closed_at do
    nil
  end

  attribute :instructions do
    nil
  end

  attribute :appeal_type do
    nil
  end

  attribute :timeline_title do
    nil
  end

  attribute :hide_from_queue_table_view do
    nil
  end

  attribute :hide_from_case_timeline do
    nil
  end

  attribute :hide_from_task_snapshot do
    nil
  end

  attribute :docket_range_date do
    nil
  end

  attribute :external_hearing_id do
    nil
  end

  attribute :available_hearing_locations do
    nil
  end

  attribute :previous_task do
    {
      assigned_at: nil
    }
  end

  attribute :available_actions do
    []
  end

  attribute :cancelled_by do
    {
      css_id: nil
    }
  end
  attribute :converted_by do
    {
      css_id: nil
    }
  end
  attribute :converted_on do
    nil
  end
end
