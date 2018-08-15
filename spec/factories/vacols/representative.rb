FactoryBot.define do
  factory :representative, class: VACOLS::Representative do
    sequence(:repkey)
    sequence(:repaddtime) do |n|
      2.years.ago - n.days
    end
    reptype "A"
  end
end
