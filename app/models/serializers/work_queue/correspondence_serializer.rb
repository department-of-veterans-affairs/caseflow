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
  attribute :veteran_id
  attribute :correspondence_documents do |object|
    object.correspondence_documents.map do |document|
      WorkQueue::CorrespondenceDocumentSerializer.new(document).serializable_hash[:data][:attributes]
    end
  end

  attribute :correspondence_type do |object|
    object.correspondence_type&.name
  end

  attribute :veteran_full_name do |object|
    [object.veteran_full_name&.first_name, object.veteran_full_name&.last_name].join(" ")
  end

  attribute :veteran_file_number do |object|
    object.veteran&.file_number
  end

  attribute :correspondence_appeal_ids do |object|
    object.appeal_ids.map(&:to_s)
  end
end
