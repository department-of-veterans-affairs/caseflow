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

  attribute :issue_count do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name]

    if serialize_attribute?(params, columns)
      object.appeal.number_of_issues
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
    columns = [Constants.QUEUE_CONFIG.COLUMNS.DAYS_ON_HOLD.name]

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

    if serialize_attribute?(params, columns)
      {
        css_id: object.assigned_to.try(:css_id),
        is_organization: object.assigned_to.is_a?(Organization),
        name: object.appeal.assigned_to_location,
        type: object.assigned_to.class.name,
        id: object.assigned_to.id
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

  attribute :started_at do
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

  attribute :document_id do
    nil
  end

  attribute :decision_prepared_by do
    {
      first_name: nil,
      last_name: nil
    }
  end

  attribute :available_actions do
    []
  end
end
