class AddPriorityToDistributions < ActiveRecord::Migration[5.2]
  def up
    add_column :distributions, :priority_push, :boolean, comment: "Whether or not this distribution is a priority-appeals-only push to judges via a weekly job (not manually requested)"
    change_column_default :distributions, :priority_push, false
  end

  def down
    remove_column :distributions, :priority_push
  end
end
