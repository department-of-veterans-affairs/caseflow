FactoryBot.define do
  factory :decass, class: VACOLS::Decass do
    sequence(:defolder)

    deatty "100"
    deteam "A1"
    deadusr "TEST"
    deadtim { Time.current.strftime("%Y-%m-%d") }
    deassign { Time.current.strftime("%Y-%m-%d") }
    deprod nil

    trait :omo_request do
      deprod Constants::DecassWorkProductTypes::OMO_REQUEST.sample
    end

    trait :draft_decision do
      deprod Constants::DecassWorkProductTypes::DRAFT_DECISION.sample
    end
  end
end
