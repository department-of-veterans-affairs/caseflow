# frozen_string_literal: true

RSpec.describe CaseTimelineInstructionSet do
  it "can be initialized" do
    set = CaseTimelineInstructionSet.new(
      change_type: "Edited Issue",
      issue_category: "test category",
      benefit_type: "benefit type",
      original_mst: false,
      original_pact: false,
      edit_mst: true,
      edit_pact: true,
      mst_edit_reason: "MST reason",
      pact_edit_reason: "PACT reason"
    )
    expect(set).to be_a(CaseTimelineInstructionSet)
  end

  it "validates attributes" do
    expect do
      CaseTimelineInstructionSet.new(
        change_type: "Edited Issue",
        issue_category: "test category"
      )
    end.to raise_error(ArgumentError)
  end

  it "has default values for the edit and reason attributes" do
    expect do
      @set = CaseTimelineInstructionSet.new(
        change_type: "Edited Issue",
        issue_category: "test category",
        benefit_type: "benefit type",
        original_mst: false,
        original_pact: false
      )
    end.not_to raise_error

    expect(@set.edit_mst).to eq(nil)
    expect(@set.edit_pact).to eq(nil)
    expect(@set.mst_edit_reason).to eq(nil)
    expect(@set.pact_edit_reason).to eq(nil)
  end
end
