# frozen_string_literal: true

FactoryBot.define do
  factory :correspondence do
    uuid { SecureRandom.uuid }
    portal_entry_date { Time.zone.now }
    source_type { "Mail" }
    cmp_queue_id { 1 }
    cmp_packet_number { rand(1_000_000_000..9_999_999_999) }
    va_date_of_receipt { Time.zone.yesterday }
    notes { "This is a note from CMP." }
    assigned_by factory: :user

    correspondence_type
    veteran
    package_document_type

    trait :with_single_doc do
      after(:create) do |correspondence|
        create(:correspondence_document, correspondence: correspondence)
      end
    end

    trait :with_correspondence_intake_task do
      transient do
        assigned_to { User.first }
      end

      after(:create) do |correspondence, evaluator|
        create(
          :correspondence_intake_task,
          appeal: correspondence,
          assigned_to: evaluator.assigned_to,
          appeal_type: Correspondence.name
        )
      end
    end
  end

  factory :correspondence_document do
    uuid { SecureRandom.uuid }
    document_type { 1250 }
    pages { 30 }
    vbms_document_type_id { 1250 }
    association :correspondence
  end
end
