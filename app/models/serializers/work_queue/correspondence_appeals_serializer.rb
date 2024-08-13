# frozen_string_literal: true

class WorkQueue::CorrespondenceAppealsSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower

  attribute :id
  attribute :correspondences_appeals_tasks
  attribute :docket_number do |object|
    object.appeal.docket_number
  end

  attribute :veteran_name do |object|
    object.appeal.veteran
  end

  attribute :stream_type do |object|
    object.appeal.stream_type
  end

  attribute :number_of_issues do |object|
    0
  end

  attribute :status do |object|
    object.correspondence.status
    # status: cor_appeal.correspondence.status,
  end

  attribute :assigned_at do |object|
    object&.tasks[0]&.assigned_at
  end

  attribute :instructions do |object|
    object.tasks[0]&.instructions
  end

  attribute :type do |object|
    object.tasks[0]&.label
  end

  attribute :assigned_to do |object|
    object.tasks[0]&.assigned_to
  end

  attribute :correspondence do |object|
    object
  end
# end
end
