FactoryBot.define do
  factory :staff, class: VACOLS::Staff do
    sequence(:stafkey)
    sequence(:slogid) { |n| "ID#{n}"}
    sequence(:sdomainid) { |n| "BVA#{n}" }
  end
end
