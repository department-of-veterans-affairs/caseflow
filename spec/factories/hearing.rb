FactoryBot.define do
  factory :hearing do
    appeal { create(:appeal) }
    uuid { SecureRandom.uuid }
    hearing_day { create(:hearing_day) }
    scheduled_time { "8:30AM" }
  end
end
