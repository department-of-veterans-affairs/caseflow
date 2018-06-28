class WorkQueue::TaskSerializer < ActiveModel::Serializer
  attribute :type
  attribute :title
  attribute :appeal_id
  attribute :status
  attribute :assigned_to_id
  attribute :assigned_by_id
  attribute :assigned_at
  attribute :started_at
  attribute :completed_at
  attribute :placed_on_hold_at

  attribute :docket_name do
    "legacy"
  end
  attribute :docket_date do
    object.appeal.form9_date
  end
end
