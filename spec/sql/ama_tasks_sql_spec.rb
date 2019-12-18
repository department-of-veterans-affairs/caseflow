# frozen_string_literal: true

describe "AMA Tasks Tableau data source", :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  context "one row for each Appeal" do
    it "join staff tables and computes status" do
      result = execute_sql("ama-tasks")
      appeals_by_status = result.map do |r|
        [r["appeal_id"], [r["appeal_task_status.decision_status"], r["appeal_task_status.decision_status__sort_"]]]
      end.to_h

      expect(appeals_by_status).to eq(expected_report)
    end
  end
end
