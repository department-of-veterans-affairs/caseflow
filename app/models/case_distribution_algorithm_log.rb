class CaseDistributionAlgorithmLog < ApplicationRecord
  belongs_to :starting_distribution, class_name: "Distribution"
  belongs_to :ending_distribution, class_name: "Distribution"
  belongs_to :starting_case, class_name: "DistributedCase"
  belongs_to :ending_case, class_name: "DistributedCase"

  scope :past_year, -> {where(created_at: (Time.zone.now - 1.year)...Time.zone.now)}
end
