# frozen_string_literal: true

describe Seeds::CavcDashboardData do
  let(:seed) { Seeds::CavcDashboardData.new }

  context "initial values" do
    it "are set properly with no previous data" do
      expect(seed.instance_variable_get(:@cavc_docket_number_last_four)).to eq 1000
      expect(seed.instance_variable_get(:@file_number)).to eq 410_000_000
      expect(seed.instance_variable_get(:@participant_id)).to eq 810_000_000
    end

    it "are set properly when seed has been previously run" do
      Veteran.create!(file_number: 410_000_001)
      create(:cavc_remand, cavc_docket_number: format("%<y>2d-%<n>4d", y: Time.zone.now.strftime("%y"), n: 1000))

      expect(seed.instance_variable_get(:@cavc_docket_number_last_four)).to eq 1100
      expect(seed.instance_variable_get(:@file_number)).to eq 410_000_100
      expect(seed.instance_variable_get(:@participant_id)).to eq 810_000_100
    end
  end

  context "#seed!" do
    it "creates decision reasons per APPEALS-13249, creates CavcDashboardDispositions, creates appeal 4 remands" do
      seed.seed!

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
      expect(CavcDecisionReason.find_by(decision_reason: "AMA specific remand").children.count).to eq 7

      # 10 from create_cavc_dashboard_dispositions, 4 from create_appeals_with_multiple_cavc_remands,
      # 10 from create_cavc_dashboard_issues
      expect(CavcRemand.count).to eq 25
      expect(CavcDashboardDisposition.count).to be >= 30

      # ensure creation of multiple remands with the same source appeal
      last_four_remands = CavcRemand.last(4)
      expect(last_four_remands.map(&:source_appeal_id).count).to eq 4
      expect(last_four_remands.map(&:source_appeal_id).uniq.count).to eq 2
      expect(last_four_remands.map(&:remand_appeal_id).uniq.count).to eq 4
    end

    it "creates all selection_bases for dispositions per APPEALS-13250" do
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
end
