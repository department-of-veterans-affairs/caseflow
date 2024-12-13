class AddNotNullConstraintToSchedulableCutoffColumn < ActiveRecord::Migration[6.1]
  def change
    change_column_null :schedulable_cutoff_dates, :cutoff_date, false
  end
end
