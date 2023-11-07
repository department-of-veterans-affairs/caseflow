class CaseDistributionAuditLeverEntry < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :case_distribution_lever
end
