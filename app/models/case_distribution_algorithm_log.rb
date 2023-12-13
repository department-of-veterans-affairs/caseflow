class CaseDistributionAlgorithmLog < ApplicationRecord
	scope :past_year, -> {where(created_at: (Time.zone.now - 1.year)...Time.zone.now)}
end
