class CaseDistributionLever < ApplicationRecord

  validates :item, presence: true
  validates :title, presence: true
  validates :data_type, presence: true
  validates :value, presence: true
  validates :is_active, inclusion: { in: [true, false] }
  validates :is_disabled, inclusion: { in: [true, false] }

  self.table_name = "case_distribution_levers"
end
