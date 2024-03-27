# frozen_string_literal: true

class WorkQueue::CorrespondenceTaskColumnSerializer
  include FastJsonapi::ObjectSerializer

  def self.serialize_attribute?(params, columns)
    (params[:columns] & columns).any?
  end

  attribute :unique_id do |object|
    object.id.to_s
  end

  attribute :instructions

  attribute :nod

  attribute :veteran_details do |object|
    vet = Veteran.find(object.correspondence.veteran_id)
    "#{vet.first_name} #{vet.last_name} (#{vet.file_number})"
  end

  attribute :notes do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.NOTES.name]
    if serialize_attribute?(params, columns)
      object.correspondence.notes
    end
  end

  attribute :closed_at do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.CORRESPONDENCE_TASK_CLOSED_DATE.name]

    if serialize_attribute?(params, columns)
      object.completed_by_date
    end
  end

  attribute :days_waiting do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING_CORRESPONDENCE.name]

    if serialize_attribute?(params, columns)
      object.days_waiting
    end
  end

  attribute :va_date_of_receipt do |object|
    object.correspondence.va_date_of_receipt
  end

  attribute :label do |object, params|
    columns = [
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.ACTION_TYPE.name
    ]

    if serialize_attribute?(params, columns)
      object.label
    end
  end

  attribute :assigned_at

  attribute :task_url

  attribute :parent_task_url do |object|
    if object.is_a?(ReassignPackageTask) || object.is_a?(RemovePackageTask)
      { parent_task_url: object.parent.task_url }
    else
      { parent_task_url: "" }
    end
  end

  attribute :assigned_to do |object, params|
    columns = [
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name
    ]
    assignee = object.assigned_to

    if serialize_attribute?(params, columns)
      {
        name: assignee.is_a?(Organization) ? assignee.name : assignee.css_id
      }
    else
      {
        name: nil
      }
    end
  end

  attribute :assigned_by do |object, params|
    columns = [
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNED_BY.name
    ]

    if serialize_attribute?(params, columns)
      {
        first_name: object.assigned_by_display_name.first,
        last_name: object.assigned_by_display_name.last
      }
    else
      {
        first_name: nil,
        last_name: nil
      }
    end
  end
end
