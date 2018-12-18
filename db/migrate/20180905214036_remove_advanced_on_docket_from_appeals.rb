class RemoveAdvancedOnDocketFromAppeals < ActiveRecord::Migration[5.1]
  def change
    remove_column :appeals, :advanced_on_docket, :boolean
  end
end
