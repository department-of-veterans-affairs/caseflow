# frozen_string_literal: true

require "support/database_cleaner"

describe "AMA Tasks Tableau data source", :postgres do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  context "one row for each Appeal" do
    it "join staff tables and computes status" do
      result = execute_sql("ama-tasks")
      appeals_by_status = result.map { |r| [r["appeal_id"], r["appeal_task_status.decision_status"]] }.to_h

      expect(appeals_by_status).to eq(expected_report)
    end
  end
end
