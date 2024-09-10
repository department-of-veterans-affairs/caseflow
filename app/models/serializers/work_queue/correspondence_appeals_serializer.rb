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

  attribute :appeal_uuid do |object|
    object.appeal.uuid
  end

  attribute :appeal_type do |object|
    object.appeal.docket_type
  end

  attribute :number_of_issues do |object|
    object.appeal.issues.length
  end

  attribute :task_added_data do |object|
    tasks = []
    object.correspondences_appeals_tasks.each do |cor_app_task|
      assigned_to = cor_app_task.task.assigned_to
      assigned_to_text = assigned_to.is_a?(Organization) ? assigned_to.name : assigned_to.css_id
      task_data = {
        assigned_at: cor_app_task.task.assigned_at,
        assigned_to: assigned_to_text,
        assigned_to_type: cor_app_task.task.assigned_to_type,
        instructions: cor_app_task.task.instructions,
        label: cor_app_task.task.label
      }
      tasks << task_data
    end
    tasks
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
