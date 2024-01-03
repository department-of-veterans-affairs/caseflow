class CaseDistributionAuditLeverEntry < ApplicationRecord
  belongs_to :user
  belongs_to :case_distribution_lever

  scope :past_year, -> { where(created_at: (Time.zone.now - 1.year)...Time.zone.now)}
end
