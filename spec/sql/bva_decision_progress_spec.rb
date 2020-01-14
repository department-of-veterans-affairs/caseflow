# frozen_string_literal: true

describe "BVA Decision Progress report", :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  context "expected report" do
    let(:expected_report) do
      [
        { "decision_status" => "1. Not distributed", "num" => 1 },
        { "decision_status" => "2. Distributed to judge", "num" => 1 },
        { "decision_status" => "3. Assigned to attorney", "num" => 2 },
        { "decision_status" => "4. Assigned to colocated", "num" => 1 },
        { "decision_status" => "5. Decision in progress", "num" => 1 },
        { "decision_status" => "6. Decision ready for signature", "num" => 1 },
        { "decision_status" => "7. Decision signed", "num" => 1 },
        { "decision_status" => "8. Decision dispatched", "num" => 1 },
        { "decision_status" => "CANCELLED", "num" => 1 },
        { "decision_status" => "MISC", "num" => 1 },
        { "decision_status" => "ON HOLD", "num" => 2 }
      ]
    end

    it "generates correct report" do
      expect_sql("bva-decision-progress").to eq(expected_report)
    end
  end
end
