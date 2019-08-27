FactoryBot.define do
  factory :message do
    text { "MyString" }
    read_at { "2019-08-27 09:24:52" }
    user_id { 1 }
  end
end
