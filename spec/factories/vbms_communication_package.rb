# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_communication_package do
    comm_package_name {}
    created_at
    created_by_id
    document_referenced
    file_number
    status
    updated_at
    updated_by_id
    vbms_uploaded_document_id
  end
end
