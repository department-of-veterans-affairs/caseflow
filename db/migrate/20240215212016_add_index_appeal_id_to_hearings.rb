class AddIndexAppealIdToHearings < Caseflow::Migration
  def change
    add_index :hearings, :appeal_id, algorithm: :concurrently
  end
end
