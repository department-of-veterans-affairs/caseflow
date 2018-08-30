FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "ORG_#{n}" }
    sequence(:feature) { |n| "org_queue_#{n}" }
    sequence(:url) { |n| "org_queue_#{n}" }

    factory :vso do
      type "Vso"
    end

    factory :bva do
      type "Bva"
    end
  end
end
