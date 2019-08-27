FactoryBot.define do
  factory :message do
    text { "hello world" }
    association :user
  end
end
