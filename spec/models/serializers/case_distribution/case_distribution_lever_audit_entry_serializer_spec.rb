# frozen_string_literal: true

describe CaseDistributionAuditLeverEntrySerializer do
  let!(:lever_user) { create(:lever_user) }
  let!(:lever) {create(:case_distribution_lever,
    item: "lever_1",
    title: "lever 1",
    description: "This is the first lever. It is a boolean with the default value of true. Therefore there should be a two radio buttons that display true and false as the example with true being the default option chosen. This lever is active so it should be in the active lever section",
    data_type: "boolean",
    value: true,
    unit: ""
  )}

  let!(:audit_lever_entry) {create(:case_distribution_audit_lever_entry,
    user: lever_user,
    created_at: "2023-07-01 10:10:01",
    previous_value: 10,
    update_value: 42,
    case_distribution_lever: lever
  )}

  it "serializes a CaseDistributionAuditLeverEntry" do
    entry = subject.new(audit_lever_entry).serializable_hash[:data][:attributes]

    expect(entry[:user_name]).to equal(lever_user.full_name)

    expect(entry[:id].to equal(audit_lever_entry.id))
    expect(entry[:case_distribution_lever_id].to equal(audit_lever_entry.case_distribution_lever_id))
    expect(entry[:created_at].to equal(audit_lever_entry.created_at))
    expect(entry[:previous_value].to equal(audit_lever_entry.previous_value))
    expect(entry[:update_value].to equal(audit_lever_entry.update_value))
  end
end