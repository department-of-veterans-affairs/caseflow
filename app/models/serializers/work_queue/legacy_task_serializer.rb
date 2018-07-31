class WorkQueue::LegacyTaskSerializer < ActiveModel::Serializer
  attribute :assigned_on
  attribute :due_on
  attribute :docket_name
  attribute :docket_date
  attribute :appeal_id
  attribute :user_id
  attribute :assigned_to_pg_id
  attribute :added_by_name
  attribute :added_by_css_id
  attribute :task_id
  attribute :task_type
  attribute :document_id
  attribute :assigned_by_first_name
  attribute :assigned_by_last_name
  attribute :work_product
  attribute :previous_task do
    {
      assigned_on: object.assigned_at
    }
  end

  attribute :docket_name do
    "Legacy"
  end

  attribute :case_type do
    "LegacyAppeal"
  end

  attribute :docket_number do
    object.appeal.docket_number
  end

  attribute :veteran_name do
    object.appeal.veteran_name
  end

  attribute :veteran_file_number do
    object.appeal.veteran_file_number
  end
end
