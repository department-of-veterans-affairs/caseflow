# frozen_string_literal: true

class WorkQueue::TaskSerializer
  include FastJsonapi::ObjectSerializer
  attribute :is_legacy do
    false
  end
  attribute :type
  attribute :label
  attribute :appeal_id
  attribute :status
  attribute :assigned_at
  attribute :started_at
  attribute :created_at
  attribute :closed_at
  attribute :instructions do |object|
    object.instructions.presence || object.default_instructions.presence || []
  end
  attribute :appeal_type
  attribute :parent_id
  attribute :timeline_title
  attribute :hide_from_queue_table_view
  attribute :hide_from_case_timeline
  attribute :hide_from_task_snapshot

  attribute :assigned_by do |object|
    {
      first_name: object.assigned_by_display_name.first,
      last_name: object.assigned_by_display_name.last,
      full_name: object.assigned_by.try(:full_name),
      css_id: object.assigned_by.try(:css_id),
      pg_id: object.assigned_by.try(:id)
    }
  end

  attribute :assigned_to do |object|
    assignee = object.assigned_to

    {
      css_id: assignee.try(:css_id),
      full_name: assignee.try(:full_name),
      is_organization: assignee.is_a?(Organization),
      name: assignee.is_a?(Organization) ? assignee.name : assignee.css_id,
      type: assignee.class.name,
      id: assignee.id
    }
  end

  attribute :cancelled_by do |object|
    {
      css_id: object.cancelled_by.try(:css_id)
    }
  end

  # only ChangeHearingRequestType defines a convertedBy deriving the data from paper_trail
  # refers to the conversion of hearing request type
  attribute :converted_by do |object|
    {
      css_id: object.try(:converted_by).try(:css_id)
    }
  end

  # ChangeHearingRequestType defines a converted_on
  # refers to when the hearing request type was converted and is equivalent to closed_at
  attribute :converted_on do |object|
    object.try(:converted_on)
  end

  attribute :assignee_name do |object|
    object.assigned_to.is_a?(Organization) ? object.assigned_to.name : object.assigned_to.css_id
  end

  attribute :placed_on_hold_at, &:calculated_placed_on_hold_at

  attribute :on_hold_duration, &:calculated_on_hold_duration

  attribute :docket_name do |object|
    object.appeal.try(:docket_name)
  end

  attribute :case_type do |object|
    object.appeal.try(:type)
  end

  attribute :docket_number do |object|
    object.appeal.try(:docket_number)
  end

  attribute :docket_range_date do |object|
    if object.appeal.is_a?(LegacyAppeal)
      object.appeal.try(:docket_date)
    else
      object.appeal.try(:docket_range_date)
    end
  end

  attribute :veteran_full_name do |object|
    object.appeal.veteran_full_name
  end

  attribute :veteran_file_number do |object|
    object.appeal.veteran_file_number
  end

  attribute :closest_regional_office do |object|
    object.appeal.closest_regional_office && RegionalOffice.find!(object.appeal.closest_regional_office)
  end

  attribute :external_appeal_id do |object|
    object.appeal.external_id
  end

  attribute :aod do |object|
    object.appeal.try(:advanced_on_docket?)
  end

  attribute :overtime do |object|
    object.appeal.try(:overtime?)
  end

  attribute :veteran_appellant_deceased do |object|
    object.appeal.try(:veteran_appellant_deceased?)
  end

  attribute :issue_count do |object|
    object.appeal.is_a?(LegacyAppeal) ? object.appeal.undecided_issues.count : object.appeal.number_of_issues
  end

  attribute :external_hearing_id do |object|
    object.hearing&.external_id if object.respond_to?(:hearing)
  end

  attribute :available_hearing_locations do |object|
    object.appeal.available_hearing_locations
  end

  attribute :previous_task do |object|
    {
      assigned_at: object.previous_task.try(:assigned_at)
    }
  end

  attribute :document_id do |object|
    object.latest_attorney_case_review&.document_id
  end

  attribute :decision_prepared_by do |object|
    {
      first_name: object.prepared_by_display_name&.first,
      last_name: object.prepared_by_display_name&.last
    }
  end

  attribute :available_actions do |object, params|
    object.available_actions_unwrapper(params[:user])
  end

  attribute :can_move_on_docket_switch do |object|
    object.try(:can_move_on_docket_switch?)
  end

  attribute :unscheduled_hearing_notes do |object|
    object.try(:unscheduled_hearing_notes)
  end
end
