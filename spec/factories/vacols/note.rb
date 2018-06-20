FactoryBot.define do
  factory :note, class: VACOLS::Note do
    sequence(:tasknum)
  end
end
