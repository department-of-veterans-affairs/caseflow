class AddCreatedAtAndUpdatedAtToLegacyHearings < ActiveRecord::Migration[5.1]
  def change
    add_column :legacy_hearings, :created_at, :datetime, null: true, comment: "Automatic timestamp when row was created."
    add_column :legacy_hearings, :updated_at, :datetime, null: true, comment: "Timestamp when record was last updated."
  end
end
