class ValidateCorrespondenceForeignKeys < Caseflow::Migration
  def change
    validate_foreign_key :correspondences, :correspondence_types
    validate_foreign_key :correspondences, :package_document_types
    validate_foreign_key :correspondences, :users
    validate_foreign_key :correspondences, :veterans
  end
end
