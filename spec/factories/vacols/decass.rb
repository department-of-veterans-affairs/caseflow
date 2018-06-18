FactoryBot.define do
  factory :decass, class: VACOLS::Decass do
    sequence(:defolder)

    deatty "100"
    deteam "A1"
    deadusr "TEST"
    deadtim { Time.current.strftime("%Y-%m-%d") }
    deassign { Time.current.strftime("%Y-%m-%d") }
  end
end
