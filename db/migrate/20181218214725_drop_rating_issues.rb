class DropRatingIssues < ActiveRecord::Migration[5.1]
  def up
    drop_table :rating_issues
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
