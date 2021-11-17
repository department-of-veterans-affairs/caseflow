class IndexHearingsOnJudgeId < Caseflow::Migration
  def change
    add_safe_index :hearings, [:judge_id]
  end
end
