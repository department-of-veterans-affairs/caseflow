FactoryBot.define do
  factory :representative, class: VACOLS::Representative do
    sequence(:repkey)
    sequence(:repaddtime) { Time.now.utc }
  end
end