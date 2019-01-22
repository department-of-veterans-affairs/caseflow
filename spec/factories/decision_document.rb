FactoryBot.define do
  factory :decision_document do
    appeal { create(:appeal) }
    sequence(:citation_number) { |n| "A181#{n % 10}3456" }
    decision_date { Time.zone.today }
    redacted_document_location { "C://Windows/User/BOBLAW/Documents/Decision.docx" }

    trait :requires_processing do
      submitted_at { Time.zone.now - 1.minute }
    end

    trait :processed do
      processed_at { Time.zone.now }
    end
  end
end
