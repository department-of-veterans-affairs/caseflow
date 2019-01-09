FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "ORG_#{n}" }
    sequence(:url) { |n| "org_queue_#{n}" }

    factory :vso do
      type "Vso"
    end

    factory :bva do
      type "Bva"
    end

    factory :business_line do
      type "BusinessLine"
    end

    factory :hearings_management do
      type "HearingsManagement"
      name "Hearings Management"
    end
  end
end
