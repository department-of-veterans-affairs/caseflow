class AddAodReasonIndexToAppeals < Caseflow::Migration
  def change
    add_safe_index :appeals, :aod_reason
  end
end
