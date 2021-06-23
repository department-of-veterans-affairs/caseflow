# frozen_string_literal: true

class WorkQueue::LegacyTaskSerializer
  include FastJsonapi::ObjectSerializer

  attribute :is_legacy do
    true
  end
  attribute :type do |object|
    object.class.name
  end
  attribute :assigned_on
  attribute :docket_name
  attribute :docket_date
  attribute :docket_range_date, &:docket_date
  attribute :appeal_id
  attribute :user_id
  attribute :added_by_name
  attribute :added_by_css_id
  attribute :task_id
  attribute :label
  attribute :document_id
  attribute :work_product
  attribute :appeal_type
  attribute :timeline_title
  attribute :started_at

  attribute :previous_task do |object|
    {
      assigned_on: object.previous_task.try(:assigned_at)
    }
  end

  attribute :assigned_by do |object|
    {
      first_name: object.assigned_by_first_name,
      last_name: object.assigned_by_last_name,
      css_id: object.assigned_by_css_id,
      pg_id: object.assigned_by_pg_id
    }
  end

  attribute :assigned_to do |object|
    {
      css_id: object.user_id,
      type: "User",
      id: object.assigned_to_pg_id
    }
  end

  attribute :assignee_name do |object|
    object.appeal.location_code
  end

  attribute :case_type do |object|
    object.appeal.type
  end

  attribute :aod do |object|
    object.appeal.aod
  end

  attribute :overtime do |object|
    object.appeal.overtime?
  end

  attribute :veteran_appellant_deceased do |object|
    object.appeal.veteran_appellant_deceased?
  end

  attribute :external_appeal_id do |object|
    object.appeal.vacols_id
  end

  attribute :docket_number do |object|
    object.appeal.docket_number
  end

  attribute :veteran_full_name do |object|
    object.appeal.veteran_full_name
  end

  attribute :veteran_file_number do |object|
    object.appeal.veteran_file_number
  end

  attribute :issue_count do |object|
    object.appeal.undecided_issues.count
  end

  attribute :paper_case do |object|
    object.appeal.file_type.eql? "Paper"
  end

  attribute :available_actions do |object, params|
    object.available_actions_unwrapper(params[:user], params[:role])
  end

  attribute :latest_informal_hearing_presentation_task do |object|
    task = object.appeal.latest_informal_hearing_presentation_task

    task ? { requested_at: task.assigned_at, received_at: task.closed_at } : {}
  end
end
