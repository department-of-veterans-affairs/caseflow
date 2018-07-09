FactoryBot.define do
  factory :issue do
    sequence(:id, 100_000_000, &:to_s)

    factory :default_issue do
      disposition "Allowed"
      disposition_id "1"
      close_date 7.days.ago
      codes %w[02 15 03 5252]
      labels ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"]
      note "low back condition"
      vacols_sequence_id 1
    end
  end
end
