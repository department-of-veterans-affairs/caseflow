class RemoveHearingDataColumns < ActiveRecord::Migration[5.1]
  def change
    remove_column :hearings, :contentions
    remove_column :hearings, :evidence
    remove_column :hearings, :comments_for_attorney
  end
end
