# frozen_string_literal: true

# spec/models/case_distribution_audit_lever_entry_spec.rb

require "rails_helper"

RSpec.describe CaseDistributionAuditLeverEntry, type: :model do
  let(:user) { create(:user) }
  let!(:levers) { Seeds::CaseDistributionLevers.levers }
  let(:lever) { create(:case_distribution_lever, :ama_hearing_case_affinity_days) }

  describe ".lever_history" do
    it "returns lever history for the past year" do
      entries = [
        create(
          :case_distribution_audit_lever_entry,
          user: user,
          case_distribution_lever: lever,
          created_at: 13.months.ago
        ),
        create(
          :case_distribution_audit_lever_entry,
          user: user,
          case_distribution_lever: lever,
          created_at: 11.months.ago
        ),
        create(
          :case_distribution_audit_lever_entry,
          user: user,
          case_distribution_lever: lever,
          created_at: 2.years.ago
        ),
        create(
          :case_distribution_audit_lever_entry,
          user: user,
          case_distribution_lever: lever,
          created_at: 1.month.ago
        )

      ]

      entry_0_serialized = mock_serialize_audit_lever_entry(entries[0], lever, user)
      entry_1_serialized = mock_serialize_audit_lever_entry(entries[1], lever, user)
      entry_2_serialized = mock_serialize_audit_lever_entry(entries[2], lever, user)
      entry_3_serialized = mock_serialize_audit_lever_entry(entries[3], lever, user)

      result = described_class.lever_history

      expect(result.count).to eq(2)
      expect(result).not_to include(entry_0_serialized)
      expect(result[0][:created_at].to_date).to eq(entry_1_serialized[:created_at].to_date)
      expect(result).not_to include(entry_2_serialized)
      expect(result[1][:created_at].to_date).to eq(entry_3_serialized[:created_at].to_date)
    end
  end
end

def mock_serialize_audit_lever_entry(entry, lever, user)
  {
    id: entry.id,
    case_distribution_lever_id: lever.id,
    created_at: entry.created_at,
    previous_value: "0.07",
    update_value: "20",
    user_css_id: user.css_id,
    user_name: user.full_name,
    lever_title: lever.title,
    lever_data_type: lever.data_type,
    lever_unit: lever.unit
  }
end
