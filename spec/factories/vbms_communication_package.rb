# frozen_string_literal: true

FactoryBot.define do
  factory :vbms_communication_package do
    association :vbms_uploaded_document, factory: :vbms_uploaded_document

    created_by_id { create(:user).id }
    comm_package_name { Faker::Book.title }
    created_at { Time.zone.now }
    file_number { generate :veteran_file_number }
    status { nil }
    updated_at { Time.zone.now }
    updated_by_id { nil }
    uuid { nil }
  end
end
