# frozen_string_literal: true

class WorkQueue::TaskColumnSerializer
  include FastJsonapi::ObjectSerializer

  def self.serialize_attribute?(params, columns)
    (params[:columns] & columns).any?
  end

  attribute :instructions, &:instructions

  # Used by hasDASRecord()
  attribute :docket_name do |object|
    # TODO: Why is this try???
    # object.appeal.try(:docket_name)
    object.appeal.docket_name
  end

  attribute :appeal_receipt_date do |object|
    # TODO: .try is pointless if you have the ternary??
    # object.appeal.is_a?(LegacyAppeal) ? nil : object.appeal.try(:receipt_date)
    object.appeal.is_a?(LegacyAppeal) ? nil : object.appeal.receipt_date
  end

  attribute :docket_number do |object, _params|
    # columns = [
    #   Constants::QUEUE_CONFIG["COLUMNS"]["APPEAL_TYPE"]["name"],
    #   Constants::QUEUE_CONFIG["COLUMNS"]["DOCKET_NUMBER"]["name"]
    # ]

    # if serialize_attribute?(params, columns)
    #   # TODO: Why is this a .try? Will claim reviews ever use this serializer?
    #   # object.appeal.try(:docket_number)
    #   object.appeal.docket_number
    # end
    object.appeal.docket_number
  end

  attribute :external_appeal_id do |object, _params|
    # columns = [
    #   Constants::QUEUE_CONFIG["COLUMNS"]["CASE_DETAILS_LINK"]["name"],
    #   Constants::QUEUE_CONFIG["COLUMNS"]["BADGES"]["name"],
    #   Constants::QUEUE_CONFIG["COLUMNS"]["DOCUMENT_COUNT_READER_LINK"]["name"]
    # ]

    # if serialize_attribute?(params, columns)
    #   object.appeal.external_id
    # end
    object.appeal.external_id
  end

  attribute :paper_case do |object, _params|
    # columns = [
    #   Constants::QUEUE_CONFIG["COLUMNS"]["CASE_DETAILS_LINK"]["name"],
    #   Constants::QUEUE_CONFIG["COLUMNS"]["DOCUMENT_COUNT_READER_LINK"]["name"]
    # ]

    # if serialize_attribute?(params, columns)
    #   # TODO: This is a database call. It shouldn't be though????? Eager load should have all this information
    #   # object.appeal.respond_to?(:file_type) ? object.appeal.file_type.eql?("Paper") : nil
    #   if defined? object.appeal.file_type
    #     object.appeal.file_type.eql?("Paper")
    #   end
    #   # object.appeal.try(:file_type)&.eql?("Paper")
    #   # true
    # end
    # true
    if defined? object.appeal.file_type
      object.appeal.file_type.eql?("Paper")
    end
  end

  attribute :veteran_full_name do |object, params|
    columns = [Constants::QUEUE_CONFIG["COLUMNS"]["CASE_DETAILS_LINK"]["name"]]

    if serialize_attribute?(params, columns)
      # TODO: This is probably a DB call and possibly a BGS call if it's not redis cached. Much slower than you think
      object.appeal.veteran_full_name
    end
  end

  attribute :veteran_file_number do |object, _params|
    # columns = [Constants::QUEUE_CONFIG["COLUMNS"]["CASE_DETAILS_LINK"]["name"]]

    # if serialize_attribute?(params, columns)
    #   # TODO: This is a DB column in schema and is already loaded in memory.
    #   # The check for serialize attribute is probably slower than serializing this column
    #   object.appeal.veteran_file_number
    # end
    object.appeal.veteran_file_number
  end

  attribute :started_at do |object, _params|
    # columns = [Constants::QUEUE_CONFIG["COLUMNS"]["CASE_DETAILS_LINK"]["name"]]

    # if serialize_attribute?(params, columns)
    #   # TODO: This is a DB column in schema and is already loaded in memory.
    #   # The check for serialize attribute is probably slower than serializing this column
    #   object.started_at
    # end
    object.started_at
  end

  attribute :issue_count do |object, params|
    columns = [Constants::QUEUE_CONFIG["COLUMNS"]["ISSUE_COUNT"]["name"]]

    if serialize_attribute?(params, columns)
      # TODO: Can serialize based on cached appeals I think.
      object.appeal.is_a?(LegacyAppeal) ? object.appeal.undecided_issues.count : object.appeal.number_of_issues
      # 1
    end
  end

  attribute :issue_types do |object, params|
    columns = [Constants::QUEUE_CONFIG["COLUMNS"]["ISSUE_TYPES"]["name"]]

    if serialize_attribute?(params, columns)
      # TODO: Can serialize based on cached appeals I think.
      if object.appeal.is_a?(LegacyAppeal)
        object.appeal.issue_categories
      else
        object.appeal.request_issues.active.map(&:nonrating_issue_category)
      end.join(",")
    end
  end

  attribute :aod do |object, params|
    columns = [Constants::QUEUE_CONFIG["COLUMNS"]["APPEAL_TYPE"]["name"]]

    if serialize_attribute?(params, columns)
      # TODO: See if this can be retrieved without query
      object.appeal.try(:advanced_on_docket?)
      # true
    end
  end

  attribute :case_type do |object, _params|
    # columns = [Constants::QUEUE_CONFIG["COLUMNS"]["APPEAL_TYPE"]["name"]]

    # if serialize_attribute?(params, columns)
    #   # object.appeal.try(:type)
    #   "Testing"
    # end
    object.appeal.type
  end

  attribute :label do |object, _params|
    # columns = [Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name, Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name]

    # if serialize_attribute?(params, columns)
    #   object.label
    # end
    object.label
  end

  attribute :placed_on_hold_at do |object, params|
    columns = [Constants::QUEUE_CONFIG["COLUMNS"]["DAYS_ON_HOLD"]["name"]]

    if serialize_attribute?(params, columns)
      # TODO: Unlikely to be able to fix this one
      object.calculated_placed_on_hold_at
      # Time.zone.now
    end
  end

  attribute :on_hold_duration do |object, params|
    columns = [Constants::QUEUE_CONFIG["COLUMNS"]["DAYS_ON_HOLD"]["name"]]

    if serialize_attribute?(params, columns)
      # TODO: Unlikely to be able to fix this one
      object.calculated_on_hold_duration
      # Time.zone.now
    end
  end

  attribute :status do |object, _params|
    # columns = [
    #   Constants::QUEUE_CONFIG["COLUMNS"]["DAYS_ON_HOLD"]["name"],
    #   Constants::QUEUE_CONFIG["COLUMNS"]["CASE_DETAILS_LINK"]["name"]
    # ]

    # if serialize_attribute?(params, columns)
    #   object.status
    # end
    object.status
  end

  attribute :assigned_at do |object, _params|
    # columns = [
    #   Constants::QUEUE_CONFIG["COLUMNS"]["DAYS_WAITING"]["name"],
    #   Constants::QUEUE_CONFIG["COLUMNS"]["BOARD_INTAKE"]["name"]
    # ]

    # if serialize_attribute?(params, columns)
    #   object.assigned_at
    # end
    object.assigned_at
  end

  attribute :closest_regional_office do |object, _params|
    # columns = [Constants::QUEUE_CONFIG["COLUMNS"]["REGIONAL_OFFICE"]["name"]]

    # if serialize_attribute?(params, columns)
    #   object.appeal.closest_regional_office && RegionalOffice.find!(object.appeal.closest_regional_office)
    # end
    object.appeal.closest_regional_office && RegionalOffice.find!(object.appeal.closest_regional_office)
  end

  attribute :assigned_to do |object, _params|
    # columns = [
    #   Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name,
    #   Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name
    # ]
    assignee = object.assigned_to

    # if serialize_attribute?(params, columns)
    if assignee
      {
        css_id: assignee.css_id,
        is_organization: assignee.is_a?(Organization),
        name: assignee.name,
        type: object.assigned_to_type,
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
    assigned_by = object.assigned_by
    if assigned_by
      display_name = object.assigned_by_display_name
      {
        first_name: display_name[0],
        last_name: display_name[1],
        css_id: assigned_by.css_id,
        pg_id: assigned_by.id
      }
    else
      {
        first_name: "",
        last_name: "",
        css_id: nil,
        pg_id: nil
      }
    end
  end

  # Used by /hearings/schedule/assign. Not present in the full `task_serializer`.
  attribute :hearing_request_type do |object, _params|
    # columns = [Constants.QUEUE_CONFIG.HEARING_REQUEST_TYPE_COLUMN_NAME]

    # if serialize_attribute?(params, columns)
    #   # The `hearing_request_type` field doesn't exist on the actual model. This
    #   # field needs to be added in a select statement and represents the field from
    #   # the `cached_appeal_attributes` table in `Hearings::ScheduleHearingTasksController`.
    #   object&.[](:hearing_request_type)
    # end
    # object&.[](:hearing_request_type)
    object[:hearing_request_type]
  end

  # Used by /hearings/schedule/assign. Not present in the full `task_serializer`.
  # former_travel technically isn't it's own column, it's part of
  # hearing request type column
  attribute :former_travel do |object, _params|
    # columns = [Constants.QUEUE_CONFIG.HEARING_REQUEST_TYPE_COLUMN_NAME]

    # if serialize_attribute?(params, columns)
    #   # The `former_travel` field doesn't exist on the actual model. This
    #   # field needs to be added in a select statement and represents the field from
    #   # the `cached_appeal_attributes` table in `Hearings::ScheduleHearingTasksController`.
    #   object&.[](:former_travel)
    # end
    # object&.[](:former_travel)
    object[:former_travel]
  end

  # Used by /hearings/schedule/assign. Not present in the full `task_serializer`.
  attribute :power_of_attorney_name do |object, _params|
    # columns = [Constants.QUEUE_CONFIG.POWER_OF_ATTORNEY_COLUMN_NAME]

    # if serialize_attribute?(params, columns)
    #   # The `power_of_attorney_name` field doesn't exist on the actual model. This
    #   # field needs to be added in a select statement and represents the field from
    #   # the `cached_appeal_attributes` table in `Hearings::ScheduleHearingTasksController`.
    #   object&.[](:power_of_attorney_name)
    # end
    # object&.[](:power_of_attorney_name)
    object[:power_of_attorney_name]
  end

  # Used by /hearings/schedule/assign. Not present in the full `task_serializer`.
  attribute :suggested_hearing_location do |object, _params|
    # columns = [Constants.QUEUE_CONFIG.SUGGESTED_HEARING_LOCATION_COLUMN_NAME]

    # if serialize_attribute?(params, columns)
    # TODO: See if this one matters
    # object.appeal.suggested_hearing_location&.to_hash
    # {}
    # end
    object.appeal.suggested_hearing_location&.to_hash
  end

  attribute :overtime do |object, params|
    columns = [Constants::QUEUE_CONFIG["COLUMNS"]["BADGES"]["name"]]

    if serialize_attribute?(params, columns)
      # This should be preloaded??
      # object.appeal.try(:overtime?)
      object.appeal.overtime?
      # true
    end
  end

  attribute :contested_claim do |object, params|
    columns = [Constants::QUEUE_CONFIG["COLUMNS"]["BADGES"]["name"]]

    if serialize_attribute?(params, columns)
      # object.appeal.try(:contested_claim?)
      object.appeal.contested_claim?
      # true
    end
  end

  attribute :mst do |object, params|
    columns = [Constants::QUEUE_CONFIG["COLUMNS"]["BADGES"]["name"]]

    if serialize_attribute?(params, columns)
      # object.appeal.try(:mst?)
      object.appeal.mst?
    end
  end

  attribute :pact do |object, params|
    columns = [Constants::QUEUE_CONFIG["COLUMNS"]["BADGES"]["name"]]

    if serialize_attribute?(params, columns)
      # object.appeal.try(:pact?)
      object.appeal.pact?
    end
  end

  attribute :veteran_appellant_deceased do |object, params|
    columns = [Constants::QUEUE_CONFIG["COLUMNS"]["BADGES"]["name"]]

    if serialize_attribute?(params, columns)
      begin
        # object.appeal.try(:veteran_appellant_deceased?)
        object.appeal.veteran_appellant_deceased?
        # true
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
    columns = [Constants::QUEUE_CONFIG["COLUMNS"]["DOCUMENT_ID"]["name"]]

    if serialize_attribute?(params, columns)
      object.latest_attorney_case_review&.document_id
    end
  end

  attribute :decision_prepared_by do |object, params|
    columns = [Constants::QUEUE_CONFIG["COLUMNS"]["DOCUMENT_ID"]["name"]]

    if serialize_attribute?(params, columns)
      name = object.prepared_by_display_name
      if name
        {
          first_name: name.first,
          last_name: name.last
        }
      else
        {
          first_name: nil,
          last_name: nil
        }
      end
      # object.prepared_by_display_name || { first_name: nil, last_name: nil }
      # { first_name: nil, last_name: nil }
    end
  end

  attribute :latest_informal_hearing_presentation_task do |object, params|
    columns = [
      Constants::QUEUE_CONFIG["COLUMNS"]["TASK_TYPE"]["name"],
      Constants::QUEUE_CONFIG["COLUMNS"]["DAYS_WAITING"]["name"]
    ]

    if serialize_attribute?(params, columns)
      task = object.appeal.latest_informal_hearing_presentation_task

      task ? { requested_at: task.assigned_at, received_at: task.closed_at } : {}
      # {}
    end
  end

  attribute :owned_by do |object, _params|
    object.assigned_to&.name
  end

  attribute :days_since_last_status_change do |object, _params|
    object.calculated_last_change_duration
  end

  attribute :days_since_board_intake do |object, _params|
    object.calculated_duration_from_board_intake
  end

  attribute :appeal_type

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
