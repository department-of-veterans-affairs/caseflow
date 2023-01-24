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

  it "#seed! creates all selection_bases for dispositions per APPEALS-13250" do
    Seeds::CavcSelectionBasisData.new.seed!

    expect(CavcSelectionBasis.where(category: "other_due_process_protection").count).to eq 18
    expect(CavcSelectionBasis.where(category: "prior_examination_inadequate").count).to eq 200
    expect(CavcSelectionBasis.where(category: "prior_opinion_inadequate").count).to eq 205
    expect(CavcSelectionBasis.where(category: "consider_statute").count).to eq 19
    expect(CavcSelectionBasis.where(category: "consider_regulation").count).to eq 81
    expect(CavcSelectionBasis.where(category: "consider_diagnostic_code").count).to eq 1066
    expect(CavcSelectionBasis.where(category: "consider_caselaw").count).to eq 196
    expect(CavcSelectionBasis.where(category: "misapplication_statute").count).to eq 19
    expect(CavcSelectionBasis.where(category: "misapplication_regulation").count).to eq 81
    expect(CavcSelectionBasis.where(category: "misapplication_diagnostic_code").count).to eq 1066
    expect(CavcSelectionBasis.where(category: "misapplication_caselaw").count).to eq 196
  end
end
