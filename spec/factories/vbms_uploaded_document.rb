# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_uploaded_document do
    association :appeal
    document_type { "Status Letter" }
  end
end
