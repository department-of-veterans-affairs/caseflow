# frozen_string_literal: true

describe CavcDecisionReason, :postgres do
  before do
    parent = CavcDecisionReason.create(decision_reason: "Test Parent", order: 1)
    CavcDecisionReason.create(decision_reason: "Test Not Parent", order: 2)
    CavcDecisionReason.create(decision_reason: "Test Child 1", parent_decision_reason_id: parent.id, order: 1)
    CavcDecisionReason.create(decision_reason: "Test Child 2", parent_decision_reason_id: parent.id, order: 2)
  end

  it "Parent reasons can access children, parent reasons have no parent" do
    parent = CavcDecisionReason.find_by(decision_reason: "Test Parent")
    non_parent = CavcDecisionReason.find_by(decision_reason: "Test Not Parent")
    expect(parent.children.count).to eq 2
    expect(parent.parent).to be nil
    expect(non_parent.children.count).to eq 0
    expect(non_parent.parent).to be nil
  end

  it "Child reasons can access parent" do
    children = CavcDecisionReason.all.reject { |reason| reason.parent_decision_reason_id.nil? }
    children.each do |child|
      expect(child.parent).not_to be nil
      expect(child.children.count).to be 0
    end
  end
end
