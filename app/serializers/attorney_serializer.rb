# frozen_string_literal: true

class AttorneySerializer
  include JSONAPI::Serializer
  attribute :id
  attribute :css_id
  attribute :full_name
  attribute :active_task_count do |object|
    object.tasks.active.size + QueueRepository.tasks_for_user(object.css_id).count
  end
end
