# frozen_string_literal: true

class SentEmailEventSerializer
  include FastJsonapi::ObjectSerializer

  attribute :recipient_role
  attribute :email_type
  attribute :email_address
  attribute :sent_at
  attribute :sent_by
end
