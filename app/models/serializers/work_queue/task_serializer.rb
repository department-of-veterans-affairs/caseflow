class WorkQueue::TaskSerializer < ActiveModel::Serializer
  attribute :is_legacy do
    false
  end
  attribute :type
  attribute :label
  attribute :appeal_id
  attribute :status
  attribute :assigned_at
  attribute :started_at
  attribute :completed_at
  attribute :placed_on_hold_at
  attribute :on_hold_duration
  attribute :instructions
  attribute :appeal_type
  attribute :timeline_title

  attribute :assigned_by do
    {
      first_name: object.assigned_by_display_name.first,
      last_name: object.assigned_by_display_name.last,
      css_id: object.assigned_by.try(:css_id),
      pg_id: object.assigned_by.try(:id)
    }
  end

  attribute :assigned_to do
    {
      css_id: object.assigned_to.try(:css_id),
      name: object.assigned_to.try(:name),
      type: object.assigned_to.class.name,
      id: object.assigned_to.id
    }
  end

  attribute :docket_name do
    object.appeal.try(:docket_name)
  end

  attribute :case_type do
    object.appeal.try(:type)
  end

  attribute :docket_number do
    object.appeal.try(:docket_number)
  end

  attribute :veteran_full_name do
    object.appeal.veteran_full_name
  end

  attribute :veteran_file_number do
    object.appeal.veteran_file_number
  end

  attribute :external_appeal_id do
    object.appeal.external_id
  end

  attribute :aod do
    object.appeal.try(:advanced_on_docket)
  end

  attribute :issue_count do
    object.appeal.number_of_issues
  end

  attribute :previous_task do
    {
      assigned_at: object.previous_task.try(:assigned_at)
    }
  end

  attribute :document_id do
    object.latest_attorney_case_review ? object.latest_attorney_case_review.document_id : nil
  end

  attribute :decision_prepared_by do
    {
      first_name: object.prepared_by_display_name ? object.prepared_by_display_name.first : nil,
      last_name: object.prepared_by_display_name ? object.prepared_by_display_name.last : nil
    }
  end

  attribute :available_actions do
    object.available_actions_unwrapper(@instance_options[:user])
  end

  attribute :task_business_payloads do
    object.task_business_payloads.map do |payload|
      { description: payload.description, values: payload.values }
    end
  end
end
