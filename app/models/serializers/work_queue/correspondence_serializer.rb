# frozen_string_literal: true

class WorkQueue::CorrespondenceSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower

  attribute :uuid
  attribute :id
  attribute :notes
  attribute :va_date_of_receipt
  attribute :nod
  attribute :correspondence_documents do |object|
    object.correspondence_documents.map do |document|
      WorkQueue::CorrespondenceDocumentSerializer.new(document).serializable_hash[:data][:attributes]
    end
  end

  attribute :correspondence_type do |object|
    object.correspondence_type&.name
  end

  attribute :tasks_unrelated_to_appeal do |object|
    filtered_tasks = object.tasks.reject do |task|
      task.type == "ReviewPackageTask" ||
        task.type == "CorrespondenceIntakeTask" ||
        task.type == "CorrespondenceRootTask"
    end

    # next unless filtered_tasks.empty?

    tasks = []
    if filtered_tasks.empty?
      filtered_tasks.each do |task|
        tasks <<
          {
            type: task.type,
            assigned_to: task.assigned_to.name,
            assigned_at: task.assigned_at.strftime("%m/%d/%Y"),
            instructions: task.instructions
          }
      end
    end
    tasks
  end

  attribute :veteran_full_name do |object|
    [object.veteran_full_name&.first_name, object.veteran_full_name&.last_name].join(" ")
  end

  attribute :veteran_file_number do |object|
    object.veteran&.file_number
  end
end
