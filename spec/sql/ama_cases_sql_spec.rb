# frozen_string_literal: true

describe "AMA Cases Tableau data source", :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  context "expected report" do
    it "join staff tables and computes status" do
      result = execute_sql("ama-cases")
      appeals_by_status = result.map do |r|
        [r["id"], [r["appeal_task_status.decision_status"], r["appeal_task_status.decision_status__sort_"]]]
      end.to_h

      expect(appeals_by_status).to eq(expected_report)
    end

    it "calculates age and AOD based on person.dob" do
      result = execute_sql("ama-cases")

      aod_case = result.find { |r| r["id"] == not_distributed_with_timed_hold.id }
      non_aod_case = result.find { |r| r["id"] == not_distributed.id }

      expect(aod_case["aod_is_advanced_on_docket"]).to eq(true)
      expect(aod_case["aod_veteran.age"]).to eq(76)

      expect(non_aod_case["aod_is_advanced_on_docket"]).to eq(false)
      expect(non_aod_case["aod_veteran.age"]).to eq(65)
    end
  end
end
