# frozen_string_literal: true

class WorkQueue::CorrespondenceAppealsSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower

  attribute :id, &:appeal_id
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

  attribute :appeal_uuid do |object|
    object.appeal.uuid
  end

  attribute :appeal_type do |object|
    object.appeal.docket_type
  end

  attribute :number_of_issues do |object|
    object.appeal.issues.length
  end

  attribute :appeal do |object|
    WorkQueue::AppealSerializer.new(object.appeal, params: { user: RequestStore[:current_user] })
  end

  attribute :task_added_data do |object|
    AmaAndLegacyTaskSerializer.create_and_preload_legacy_appeals(
      params: { user: RequestStore[:current_user], role: "generic" },
      tasks: object.tasks,
      ama_serializer: WorkQueue::TaskSerializer
    ).call
  end

  attribute :status do |object|
    object.correspondence.status
  end

  attribute :assigned_to do |object|
    object.tasks[0]&.assigned_to
  end

  attribute :correspondence do |object|
    object
  end
end
