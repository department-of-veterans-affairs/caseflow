class WorkQueue::TaskSerializer < ActiveModel::Serializer
  attribute :type
  attribute :title
  attribute :appeal_id
  attribute :status
  attribute :assigned_to
  attribute :assigned_by
  attribute :assigned_at
  attribute :started_at
  attribute :completed_at
  attribute :placed_on_hold_at
  attribute :instructions

  attribute :docket_name do
    object.appeal.docket_name
  end

  attribute :case_type do
    object.appeal.type
  end

  attribute :docket_number do
    object.appeal.docket_number
  end
end
