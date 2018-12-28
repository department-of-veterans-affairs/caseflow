class DropHearingsTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :hearings
  end
end
