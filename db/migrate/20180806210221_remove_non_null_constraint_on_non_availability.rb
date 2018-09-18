class RemoveNonNullConstraintOnNonAvailability < ActiveRecord::Migration[5.1]
  def change
    change_column :non_availabilities, :date, :date, :null => true
  end
end
