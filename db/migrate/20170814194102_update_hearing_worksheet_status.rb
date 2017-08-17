class UpdateHearingWorksheetStatus < ActiveRecord::Migration
  def change
    remove_column :issues, :hearing_worksheet_status, :integer
    add_column :issues, :allow, :boolean
    add_column :issues, :deny, :boolean
    add_column :issues, :remand, :boolean
    add_column :issues, :dismiss, :boolean
  end
end
