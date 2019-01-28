FactoryBot.define do
  factory :board_grant_effectuation do
    granted_decision_issue do
      create(
        :decision_issue,
        :rating,
        disposition: "allowed",
        decision_review: decision_document.appeal
      )
    end

    decision_document do
      create(:decision_document)
    end

    trait :requires_processing do
      submitted_at { Time.zone.now - 1.minute }
    end

    trait :processed do
      processed_at { Time.zone.now }
    end
  end
end
