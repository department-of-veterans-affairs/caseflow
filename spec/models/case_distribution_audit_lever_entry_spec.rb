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

      entry_0_serialized = {
        id: entries[0].id,
        case_distribution_lever_id: lever.id,
        created_at: entries[0].created_at,
        previous_value: nil,
        update_value: nil,
        user_css_id: user.css_id,
        user_name: user.full_name,
        lever_title: lever.title,
        lever_data_type: lever.data_type,
        lever_unit: lever.unit
      }

      entry_1_serialized = {
        id: entries[1].id,
        case_distribution_lever_id: lever.id,
        created_at: entries[1].created_at,
        previous_value: nil,
        update_value: nil,
        user_css_id: user.css_id,
        user_name: user.full_name,
        lever_title: lever.title,
        lever_data_type: lever.data_type,
        lever_unit: lever.unit
      }

      entry_2_serialized = {
        id: entries[2].id,
        case_distribution_lever_id: lever.id,
        created_at: entries[2].created_at,
        previous_value: nil,
        update_value: nil,
        user_css_id: user.css_id,
        user_name: user.full_name,
        lever_title: lever.title,
        lever_data_type: lever.data_type,
        lever_unit: lever.unit
      }

      entry_3_serialized = {
        id: entries[3].id,
        case_distribution_lever_id: lever.id,
        created_at: entries[3].created_at,
        previous_value: nil,
        update_value: nil,
        user_css_id: user.css_id,
        user_name: user.full_name,
        lever_title: lever.title,
        lever_data_type: lever.data_type,
        lever_unit: lever.unit
      }

      result = described_class.lever_history

      expect(result).not_to include(entry_0_serialized)
      expect(result).to include(entry_1_serialized)
      expect(result).not_to include(entry_2_serialized)
      expect(result).to include(entry_3_serialized)
    end
  end
end
