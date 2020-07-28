class AddAgeAodIndexToAppeals < Caseflow::Migration
  def change
    add_safe_index :appeals, :aod_based_on_age
  end
end
