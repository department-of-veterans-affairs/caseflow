# frozen_string_literal: true

require "support/database_cleaner"

describe "BVA Decision Progress report", :postgres do
  include SQLHelpers

  context "one row for each category" do
    let(:expected_report) do
      [
        { "decision_status" => "1. Not distributed", "num" => 0 },
        { "decision_status" => "2. Distributed to judge", "num" => 0 },
        { "decision_status" => "3. Assigned to attorney", "num" => 0 },
        { "decision_status" => "4. Assigned to colocated", "num" => 0 },
        { "decision_status" => "5. Decision in progress", "num" => 0 },
        { "decision_status" => "6. Decision ready for signature", "num" => 0 },
        { "decision_status" => "7. Decision signed", "num" => 0 },
        { "decision_status" => "8. Decision dispatched", "num" => 0 },
        { "decision_status" => "CANCELLED", "num" => 0 },
        { "decision_status" => "MISC", "num" => 0 },
        { "decision_status" => "ON HOLD", "num" => 0 }
      ]
    end

    it "generates correct report" do
      expect_sql("bva-decision-progress").to eq(expected_report)
    end
  end
end
