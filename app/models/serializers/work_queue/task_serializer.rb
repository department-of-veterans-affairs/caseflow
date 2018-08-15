class WorkQueue::TaskSerializer < ActiveModel::Serializer
  attribute :type
  attribute :action
  attribute :appeal_id
  attribute :status
  attribute :assigned_to
  attribute :assigned_at
  attribute :started_at
  attribute :completed_at
  attribute :placed_on_hold_at
  attribute :instructions
  attribute :appeal_type

  attribute :assigned_by do
    {
      first_name: object.assigned_by.full_name.split(" ").first,
      last_name: object.assigned_by.full_name.split(" ").last,
      css_id: object.assigned_by.css_id,
      pg_id: object.assigned_by.id
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
    object.appeal.issues.count
  end
end
