# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_uploaded_document do
    veteran_file_number { generate :veteran_file_number }
    document_type { "Status Letter" }
  end
end
