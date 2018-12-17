FactoryBot.define do
  factory :higher_level_review do
    sequence(:veteran_file_number, &:to_s)
    receipt_date { 1.month.ago }

    trait :with_end_product_establishment do
      after(:create) do |higher_level_review|
        create(:end_product_establishment,
               source: higher_level_review)
      end
    end
  end
end
