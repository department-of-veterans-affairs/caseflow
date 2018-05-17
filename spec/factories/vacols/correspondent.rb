FactoryBot.define do
  factory :correspondent, class: VACOLS::Correspondent do
    sequence(:stafkey)
  end
end