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

  attribute :appeal do |object|
    WorkQueue::AppealSerializer.new(object.appeal, params: { user: RequestStore[:current_user] })
  end

  attribute :task_added_data do |object|
    tasks = []
    object.correspondences_appeals_tasks.each do |cor_app_task|
      task = cor_app_task.task
      assigned_to = cor_app_task.task.assigned_to
      assigned_to_text = assigned_to.is_a?(Organization) ? assigned_to.name : assigned_to.css_id
      task_data = {
        assignedOn: task.assigned_at.strftime("%m/%d/%Y"),
        assignedTo: assigned_to_text,
        assignedBy: {
          firstName: task.assigned_by_display_name.first,
          lastName: task.assigned_by_display_name.last,
          fullName: task.assigned_by.try(:full_name),
          cssId: task.assigned_by.try(:css_id)
        },
        assigned_to_type: task.assigned_to_type,
        instructions: task.instructions,
        label: task.label,
        uniqueId: task.id,
        availableActions: task.available_actions_unwrapper(RequestStore[:current_user]),
        status: task.status,
        type: task.type,
        assigneeName: task.assigned_by.try(:full_name),


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
