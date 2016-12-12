class AddCancelReasonToTask < ActiveRecord::Migration
  def change
    add_column :tasks, :cancel_reason, :string
  end
end
