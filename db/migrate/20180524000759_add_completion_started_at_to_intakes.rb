class AddCompletionStartedAtToIntakes < ActiveRecord::Migration[5.1]
  def change
    add_column :intakes, :completion_started_at, :datetime
  end
end
