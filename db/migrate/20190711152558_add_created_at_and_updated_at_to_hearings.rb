class AddCreatedAtAndUpdatedAtToHearings < ActiveRecord::Migration[5.1]
  def change
    add_column :hearings, :created_at, :datetime, null: true, comment: "Automatic timestamp when row was created."
    add_column :hearings, :updated_at, :datetime, null: true, comment: "Timestamp when record was last updated."
  end
end
