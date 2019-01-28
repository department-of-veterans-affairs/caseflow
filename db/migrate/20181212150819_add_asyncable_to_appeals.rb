class AddAsyncableToAppeals < ActiveRecord::Migration[5.1]
  def change
    add_column :appeals, :establishment_submitted_at, :datetime
    add_column :appeals, :establishment_processed_at, :datetime
    add_column :appeals, :establishment_attempted_at, :datetime
    add_column :appeals, :establishment_error, :string
  end
end
