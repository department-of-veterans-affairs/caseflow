# frozen_string_literal: true

describe Seeds::CavcDashboardData do
  it "#seed! creates all parent and child decision reasons per APPEALS-13249" do
    Seeds::CavcDashboardData.new.seed!

    expect(CavcDecisionReason.count).to eq 39
    expect(CavcDecisionReason.where(parent_decision_reason_id: nil).count).to eq 18
    expect(CavcDecisionReason.where.not(parent_decision_reason_id: nil).count).to eq 21
    expect(CavcDecisionReason.find_by(decision_reason: "Duty to assist").children.count).to eq 2
    expect(CavcDecisionReason.find_by(decision_reason: "Provide VA examination").children.count).to eq 2
    expect(CavcDecisionReason.find_by(decision_reason: "Obtain VA opinion").children.count).to eq 2
    expect(CavcDecisionReason.find_by(
      decision_reason: "Consider statute/regulation/diagnostic code/caselaw"
    ).children.count).to eq 4
    expect(CavcDecisionReason.find_by(
      decision_reason: "Misapplication of statute/regulation/diagnostic code/caselaw"
    ).children.count).to eq 4
    expect(CavcDecisionReason.find_by(decision_reason: "AMA specific remand?").children.count).to eq 7
  end
end
