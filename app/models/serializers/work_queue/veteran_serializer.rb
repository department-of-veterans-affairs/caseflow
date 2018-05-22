class WorkQueue::VeteranSerializer < ActiveModel::Serializer
  attribute :assigned_on
  attribute :due_on
  attribute :docket_name
  attribute :docket_date
  attribute :appeal_id
  attribute :user_id
  attribute :added_by_name
  attribute :added_by_css_id
  attribute :task_id
  attribute :task_type
  attribute :document_id
  attribute :assigned_by_first_name
  attribute :assigned_by_last_name
end
