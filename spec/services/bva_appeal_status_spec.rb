# frozen_string_literal: true

describe BVAAppealStatus, :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  context "one row for each category" do
    let(:sql_status) do
      result = execute_sql("ama-cases")
      result.map do |r|
        [r["id"], [r["appeal_task_status.decision_status"], r["appeal_task_status.decision_status__sort_"]]]
      end.to_h
    end

    it "computes like SQL does" do
      sql_status.each do |appeal_id, pair|
        status = pair.first
        sort_key = pair.last
        appeal = Appeal.find(appeal_id)
        appeal_status = described_class.new(tasks: appeal.tasks)

        expect(appeal_status.to_s).to eq(status)
        expect(appeal_status.to_i).to eq(sort_key.to_i + 1) # our sort keys are 1-based
      end
    end
  end
end
