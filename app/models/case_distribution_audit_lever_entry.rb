class CaseDistributionAuditLeverEntry < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :case_distribution_lever

  scope :past_year, -> { where(created_at: (Time.zone.now - 1.year)...Time.zone.now)}

  def create_entries(audit_lever_entries_list)
    audit_lever_entries_list.each do |audit_lever_entry|
      cd_audit_lever_entry = JSON.parse(audit_lever_entry, object_class: OpenStruct)
      CaseDistributionAuditLeverEntry.create!(cd_audit_lever_entry)
    end
  end
end
