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
    it "creates decision reasons per APPEALS-13249 and creates CavcDashboardDispositions" do
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
      expect(CavcDecisionReason.find_by(decision_reason: "AMA specific remand?").children.count).to eq 7

      expect(CavcRemand.count).to eq 10
      expect(CavcDashboardDisposition.count).to eq 30
    end
  end
end
