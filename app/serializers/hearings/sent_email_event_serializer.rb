# frozen_string_literal: true

class SentEmailEventSerializer
  include FastJsonapi::ObjectSerializer

  attribute :sent_to, &:sent_to_role
  attribute :email_type
  attribute :email_address
  attribute :sent_at
  attribute :sent_by do |object|
    object.sent_by.username
  end
end
