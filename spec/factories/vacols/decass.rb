FactoryBot.define do
  factory :decass, class: VACOLS::Decass do
    sequence(:defolder)

    deatty "100"
    deteam "A1"
    deadusr "TEST"
    deadtim { Time.zone.today }
    deassign { Time.zone.today }
  end
end
