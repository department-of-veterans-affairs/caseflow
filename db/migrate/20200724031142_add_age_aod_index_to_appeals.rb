class AddAgeAodIndexToAppeals < Caseflow::Migration
  def change
    add_safe_index :appeals, :age_aod
  end
end
