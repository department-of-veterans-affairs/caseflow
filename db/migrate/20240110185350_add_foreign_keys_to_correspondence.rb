class AddForeignKeysToCorrespondence < ActiveRecord::Migration[6.1]
  def change
    add_foreign_key :correspondences, :correspondence_types, validate: false
    add_foreign_key :correspondences, :veterans, validate: false
  end
end
