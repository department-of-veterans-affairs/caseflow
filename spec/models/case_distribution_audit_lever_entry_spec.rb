# spec/models/case_distribution_audit_lever_entry_spec.rb

require 'rails_helper'

RSpec.describe CaseDistributionAuditLeverEntry, type: :model do
  let(:user) { create(:user) }
  let!(:levers) {Seeds::CaseDistributionLevers.new.levers}

  describe '.lever_history' do
    it 'returns lever history for the past year' do
      lever = CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.ama_hearing_case_affinity_days)
      entries = [
        create(:case_distribution_audit_lever_entry, user: user, case_distribution_lever: lever, created_at: 13.months.ago),
        create(:case_distribution_audit_lever_entry, user: user, case_distribution_lever: lever, created_at: 11.months.ago),
        create(:case_distribution_audit_lever_entry, user: user, case_distribution_lever: lever, created_at: 2.years.ago),
        create(:case_distribution_audit_lever_entry, user: user, case_distribution_lever: lever, created_at: 1.month.ago)
      ]

      result = described_class.lever_history

      expect(result).to match_array(entries[0..1].map { |entry| entry.attributes.symbolize_keys })
    end
  end
end
