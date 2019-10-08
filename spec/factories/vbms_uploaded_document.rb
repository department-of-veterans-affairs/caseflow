# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_uploaded_document do
    appeal
    document_type { "Status Letter" }
  end
end
