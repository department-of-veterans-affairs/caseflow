# frozen_string_literal: true

class WorkQueue::CorrespondenceTaskSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id
  attribute :appeal_id
  attribute :appeal_type
  attribute :assigned_at
  attribute :assigned_by_id
  attribute :assigned_to_id
  attribute :assigned_to_type
  attribute :cancellation_reason
  attribute :cancelled_by_id
  attribute :closed_at
  attribute :completed_by_id
  attribute :created_at
  attribute :instructions
  attribute :parent_id
  attribute :placed_on_hold_at
  attribute :started_at
  attribute :status
  attribute :updated_at
  attribute :type
  # other location for task actions. Will be needed for correspondence related tasks
  attribute :available_actions do |object, params|
    object.available_actions_unwrapper(params[:user])
  end
end
