class AddPriorityToDistributions < ActiveRecord::Migration[5.2]
  def up
    add_column :distributions, :priority, :boolean, comment: "Whether or not this distribution was a priority appeals only push to judges via weekly job (not requested)"
    change_column_default :distributions, :priority, false
  end

  def down
    remove_column :distributions, :priority
  end
end