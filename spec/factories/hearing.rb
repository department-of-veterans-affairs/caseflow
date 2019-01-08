FactoryBot.define do
  factory :hearing do
    appeal { create(:appeal) }
    uuid { SecureRandom.uuid }
    hearing_day { create(:hearing_day) }
  end
end
