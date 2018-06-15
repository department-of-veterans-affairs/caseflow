FactoryBot.define do
  factory :decass, class: VACOLS::Decass do
    sequence(:defolder)

    deatty "100"
    deteam "A1"
    deadusr "TEST"
    deadtim { Time.now.strftime("%Y-%m-%d") }
    deassign { Time.now.strftime("%Y-%m-%d") }
  end
end
