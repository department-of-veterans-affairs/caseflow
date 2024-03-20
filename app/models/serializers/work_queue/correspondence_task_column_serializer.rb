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

  attribute :veteran_details do |object, params|
   columns = [Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name]

   if serialize_attribute?(params, columns)
      vet = Veteran.find(object.correspondence.veteran_id)
      "#{vet.first_name} #{vet.last_name} (#{vet.file_number})"
   end
  end

  attribute :notes do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.NOTES.name]
    if serialize_attribute?(params, columns)
      object.correspondence.notes
    end
  end

  attribute :cmp_packet_number do |object|
    object.correspondence.cmp_packet_number
  end

  attribute :closed_at_and_completed_by_date do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name]

    if serialize_attribute?(params, columns)
      object.closed_at
    end
  end

  attribute :days_waiting do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING_CORRESPONDENCE.name]

     if serialize_attribute?(params, columns)
       object.days_waiting
     end
   end

  attribute :va_date_of_receipt do |object, params|
    columns = [Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name]

    if serialize_attribute?(params, columns)
      object.correspondence.va_date_of_receipt
    end
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

  attribute :status

  attribute :assigned_at

  attribute :task_url

  attribute :assigned_to do |object, params|
    columns = [
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name
    ]
    assignee = object.assigned_to

    if serialize_attribute?(params, columns)
      {
        css_id: assignee.try(:css_id),
        name: assignee.is_a?(Organization) ? assignee.name : assignee.css_id,
        is_organization: assignee.is_a?(Organization),
        type: assignee.class.name,
        id: assignee.id
      }
    else
      {
        css_id: nil,
        is_organization: nil,
        name: nil,
        type: nil,
        id: nil
      }
    end
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
