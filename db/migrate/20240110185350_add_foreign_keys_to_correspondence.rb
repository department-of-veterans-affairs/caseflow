class AddForeignKeysToCorrespondence < Caseflow::Migration
  def change
    add_foreign_key :correspondences, :correspondence_types, validate: false
    add_foreign_key :correspondences, :package_document_types, validate: false
    add_foreign_key :correspondences, :users, column: :assigned_by_id, validate: false
    add_foreign_key :correspondences, :users, column: :updated_by_id, validate: false
    add_foreign_key :correspondences, :veterans, validate: false
  end
end
