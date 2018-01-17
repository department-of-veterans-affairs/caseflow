class WorkQueue::TaskSerializer < ActiveModel::Serializer
  attribute :assigned_on
  attribute :due_on
  attribute :docket_name
  attribute :docket_date
  attribute :appeal_id
  attribute :user_id
end
