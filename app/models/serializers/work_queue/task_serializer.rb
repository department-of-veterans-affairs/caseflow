class WorkQueue::TaskSerializer < ActiveModel::Serializer
  attribute :type
  attribute :action
  attribute :appeal_id
  attribute :status
  attribute :assigned_at
  attribute :started_at
  attribute :completed_at
  attribute :placed_on_hold_at
  attribute :on_hold_duration
  attribute :instructions
  attribute :appeal_type

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
      type: object.assigned_to.class.name,
      id: object.assigned_to.id
    }
  end

  attribute :docket_name do
    object.appeal.docket_name
  end

  attribute :case_type do
    object.appeal.type
  end

  attribute :docket_number do
    object.appeal.docket_number
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
    object.appeal.advanced_on_docket
  end

  attribute :issue_count do
    object.appeal.issue_count
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
end
