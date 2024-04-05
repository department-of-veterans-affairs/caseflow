# frozen_string_literal: true

class WorkQueue::CorrespondenceSerializer
  include FastJsonapi::ObjectSerializer

  set_key_transform :camel_lower

  attribute :uuid
  attribute :id
  attribute :cmp_packet_number
  attribute :notes
  attribute :portal_entry_date
  attribute :source_type
  attribute :va_date_of_receipt
  # Is this a future table?
  attribute :cmp_queue_id

  attribute :correspondence_type do |object|
    object.correspondence_type&.name
  end

  attribute :veteran_full_name do |object|
    [object.veteran_full_name&.first_name, object.veteran_full_name&.last_name].join(" ")
  end

  attribute :package_document_type do |object|
    object.package_document_type&.name
  end

  attribute :veteran_file_number do |object|
    object.veteran&.file_number
  end
end
