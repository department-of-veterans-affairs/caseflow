# frozen_string_literal: true

describe CaseDistributionAuditLeverEntrySerializer do
  let!(:lever_user) { create(:user) }
  # rubocop:disable Layout/LineLength
  let!(:lever) do
    create(:case_distribution_lever,
           item: "lever_1",
           title: "lever 1",
           description: "This is the first lever. It is a boolean with the default value of true. Therefore there should be a two radio buttons that display true and false as the example with true being the default option chosen. This lever is active so it should be in the active lever section",
           data_type: "boolean",
           value: true,
           unit: "",
           lever_group_order: "static")
  end
  # rubocop:enable Layout/LineLength

  let!(:audit_lever_entry) do
    create(:case_distribution_audit_lever_entry,
           user: lever_user,
           created_at: "2023-07-01 10:10:01",
           previous_value: 10,
           update_value: 42,
           case_distribution_lever: lever)
  end

  it "serializes a CaseDistributionAuditLeverEntry" do
    entry = described_class.new(audit_lever_entry).serializable_hash[:data][:attributes]

    expect(entry[:user_css_id]).to eq(lever_user.css_id)
    expect(entry[:user_name]).to eq(lever_user.full_name)
    expect(entry[:lever_title]).to eq(lever.title)
    expect(entry[:lever_data_type]).to eq(lever.data_type)
    expect(entry[:lever_unit]).to eq(lever.unit)

    expect(entry[:id]).to eq(audit_lever_entry.id)
    expect(entry[:case_distribution_lever_id]).to eq(audit_lever_entry.case_distribution_lever_id)
    expect(entry[:created_at]).to eq(audit_lever_entry.created_at)
    expect(entry[:previous_value]).to eq(audit_lever_entry.previous_value)
    expect(entry[:update_value]).to eq(audit_lever_entry.update_value)
  end

  context "#as_json" do
    it "should return serialize data" do
      entry = described_class.new(audit_lever_entry)
      expect(entry.as_json).to eq(entry.serializable_hash[:data][:attributes])
    end
  end
end
