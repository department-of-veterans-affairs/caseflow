FactoryBot.define do
  factory :representative, class: VACOLS::Representative do
    sequence(:repkey)
    sequence(:repaddtime) { |n| 2.years.ago - n.days }
    reptype "A"
  end
end
