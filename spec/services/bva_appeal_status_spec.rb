# frozen_string_literal: true

require "support/vacols_database_cleaner"

describe BVAAppealStatus, :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  context "one row for each category" do
    let(:sql_status) do
      result = execute_sql("ama-cases")
      result.map do |r|
        [r["id"], r["appeal_task_status.decision_status"]]
      end.to_h
    end

    it "computes like SQL does" do
      sql_status.each do |appeal_id, status|
        appeal = Appeal.find(appeal_id)
        appeal_status = described_class.new(appeal: appeal)

        expect(appeal_status.to_s).to eq(status)
      end
    end
  end
end
