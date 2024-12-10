# frozen_string_literal: true

class WorkQueue::CorrespondenceDetailsSerializer
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
  attribute :correspondence_type do |object|
    object.correspondence_type&.name
  end
end
