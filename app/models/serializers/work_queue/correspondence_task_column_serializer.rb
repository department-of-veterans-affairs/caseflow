# frozen_string_literal: true

class WorkQueue::CorrespondenceTaskColumnSerializer
  include FastJsonapi::ObjectSerializer

  attribute :unique_id do |object|
    object.id.to_s
  end

  attribute :instructions do |object|
    object.instructions
  end

  attribute :veteran_details do |object|
    vet = Veteran.find(object.correspondence.veteran_id)
    "#{vet.first_name} #{vet.last_name} (#{vet.file_number})"
  end

  attribute :notes do |object|
    object.correspondence.notes
  end

  attribute :cmp_packet_number do |object|
    object.correspondence.cmp_packet_number
  end

  attribute :completion_date do |object|
    object.closed_at
  end

  attribute :days_waiting do |object|
    object.days_waiting
  end

  attribute :va_date_of_receipt do |object|
    object.correspondence.va_date_of_receipt
  end

  attribute :label do |object|
    object.label
  end

  attribute :status do |object|
    object.status
  end

  attribute :assigned_at do |object|
    object.assigned_at
  end

  attribute :task_url do |object|
    object.task_url
  end

  attribute :assigned_to do |object|
    assignee = object.assigned_to
    {
      css_id: assignee.try(:css_id),
      is_organization: assignee.is_a?(Organization),
      name: assignee.is_a?(Organization) ? assignee.name : assignee.css_id,
      type: assignee.class.name,
      id: assignee.id
    }
  end

  attribute :assigned_by do |object|
    {
      first_name: object.assigned_by_display_name.first,
      last_name: object.assigned_by_display_name.last,
      css_id: object.assigned_by.try(:css_id),
      pg_id: object.assigned_by.try(:id)
    }
  end
end
