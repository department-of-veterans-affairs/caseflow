FactoryBot.define do
  factory :decass, class: VACOLS::Decass do
    sequence(:defolder)

    deatty "100"
    deteam "A1"
    deadusr "TEST"
    deadtim { Date.today }
    deassign { Date.today }
  end
end
