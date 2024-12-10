# frozen_string_literal: true

class WorkQueue::CorrespondenceSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower

  attribute :uuid
  attribute :id
  attribute :notes
  attribute :va_date_of_receipt
  attribute :nod
  attribute :status
  attribute :type
  attribute :veteran_id
  attribute :correspondence_documents do |object|
    object.correspondence_documents.map do |document|
      WorkQueue::CorrespondenceDocumentSerializer.new(document).serializable_hash[:data][:attributes]
    end
  end

  attribute :correspondence_type do |object|
    object.correspondence_type&.name
  end

  attribute :tasks_unrelated_to_appeal do |object|
    filtered_tasks = object.tasks_not_related_to_an_appeal

    tasks = []

    unless filtered_tasks.empty?
      filtered_tasks.each do |task|
        tasks <<
          {
            label: task.label,
            assignedOn: task.assigned_at.strftime("%m/%d/%Y"),
            assignedTo: (task.assigned_to_type == "Organization") ? task.assigned_to.name : task.assigned_to.css_id,
            type: task.assigned_to_type,
            instructions: task.instructions,
            availableActions: task.available_actions_unwrapper(RequestStore[:current_user]),
            uniqueId: task.id,
            reassignUsers: task&.reassign_users,
            assignedToOrg: task&.assigned_to.is_a?(Organization),
            status: task.status,
            organizations: task.reassign_organizations.map { |org| { label: org.name, value: org.id } }
          }
      end
    end
    tasks
  end

  attribute :closed_tasks_unrelated_to_appeal do |object|
    filtered_tasks = object.closed_tasks_not_related_to_an_appeal
    tasks = []

    unless filtered_tasks.empty?
      filtered_tasks.each do |task|
        tasks <<
          {
            label: task.label,
            assignedOn: task.assigned_at.strftime("%m/%d/%Y"),
            assignedTo: (task.assigned_to_type == "Organization") ? task.assigned_to.name : task.assigned_to.css_id,
            type: task.assigned_to_type,
            instructions: task.instructions,
            availableActions: task.available_actions_unwrapper(RequestStore[:current_user]),
            uniqueId: task.id,
            status: task.status
          }
      end
    end
    tasks
  end

  attribute :correspondence_appeals do |object|
    appeals = []
    object.correspondence_appeals.map do |appeal|
      appeals << WorkQueue::CorrespondenceAppealsSerializer.new(appeal).serializable_hash[:data][:attributes]
    end
    appeals
  end

  attribute :veteran_full_name do |object|
    [object.veteran_full_name&.first_name, object.veteran_full_name&.last_name].join(" ")
  end

  attribute :veteran_file_number do |object|
    object.veteran&.file_number
  end

  attribute :correspondence_appeal_ids, &:appeal_ids

  attribute :correspondence_response_letters do |object|
    object.correspondence_response_letters.map do |response_letter|
      WorkQueue::CorrespondenceResponseLetterSerializer.new(response_letter).serializable_hash[:data][:attributes]
    end
  end

  attribute :related_correspondence_ids, &:related_correspondence_ids
end
