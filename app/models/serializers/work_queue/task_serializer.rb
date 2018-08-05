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
  attribute :appeal_type

  attribute :docket_name do
    object.appeal.docket_name
  end

  attribute :case_type do
    object.appeal.type
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

  attribute :external_id do
    object.appeal.external_id
  end

  attribute :aod do
    object.appeal.advanced_on_docket
  end
end
