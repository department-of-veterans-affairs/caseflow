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
      assigned_on: object.previous_task&.assigned_at
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

  attribute :mst do |object|
    object.appeal.mst?
  end

  attribute :pact do |object|
    object.appeal.pact?
  end

  attribute :veteran_appellant_deceased do |object|
    # object.appeal.veteran_appellant_deceased?

    # If it didn't match to a veteran in the legacy work queue this will be incorrect.
    # I'm scared to check the veteran accessor though
    # TODO: See if you can set a variable like is_collection? or reference if it is a collection
    # to Switch the fast accessors vs the slow accessors on and off
    # Taken from appeal_concern.rb
    (object.appeal.veteran_date_of_death_fast && object.appeal.appellant_is_veteran)
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
    # object.appeal.veteran_file_number_fast || object.appeal.veteran_file_number
    # Same thing as veteran death date. I would like a fallback, but it slows things down
    # file_number = object.appeal.veteran_file_number_fast

    # object.appeal.veteran_file_number_fast || object.veteran_file_number
    puts "in veteran file number serialize field block"
    puts object.appeal.veteran_file_number_fast.inspect
    puts object.appeal.sanitized_vbms_id
    puts "Dying after calling veteran_file_number"

    puts object.appeal.veteran_file_number.inspect
    puts "makes it past veteran_file_number"
    # puts object.sanitized_vbms_id.inspect

    object.appeal.veteran_file_number_fast || object.appeal.veteran_file_number

    # if file_number
    #   file_number
    # else
    #   object.appeal_veteran_file_number
    # end
    # object.appeal.veteran_file_number
  end

  attribute :issue_count do |object|
    object.appeal.undecided_issues.count
  end

  attribute :paper_case do |object|
    object.appeal.paper_case?
  end

  attribute :available_actions do |object, params|
    object.available_actions_unwrapper(params[:user], params[:role])
  end

  attribute :latest_informal_hearing_presentation_task do |object|
    task = object.appeal.latest_informal_hearing_presentation_task

    task ? { requested_at: task.assigned_at, received_at: task.closed_at } : {}
  end

  attribute :instructions do |object|
    if object.class == JudgeLegacyDecisionReviewTask
      [object.appeal.attorney_case_review&.note].compact
    else
      []
    end
  end
end
