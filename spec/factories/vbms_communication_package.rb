# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_communication_package do
    comm_package_name { nil }
    created_at { Time.zone.now }
    created_by_id { nil }
    document_referenced { nil }
    file_number { nil }
    status { nil }
    updated_at { Time.zone.now }
    updated_by_id { nil }
    vbms_uploaded_document_id { nil }
  end
end
