class AddCurrentVersionIdToUnrecognizedAppellants < ActiveRecord::Migration[5.2]
  def change
    add_reference :unrecognized_appellants, :current_version, index: false, foreign_key: { to_table: :unrecognized_appellants }, comment: "The current version ID for this unrecognized appellant"
    add_reference :unrecognized_appellants, :created_by, index: false, foreign_key: { to_table: :users}, comment: "The ID of the user that created this version of the unrecognized appellant"
  end
end
