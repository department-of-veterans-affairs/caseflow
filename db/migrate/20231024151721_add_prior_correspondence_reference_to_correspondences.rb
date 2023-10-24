class AddPriorCorrespondenceReferenceToCorrespondences < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_reference :correspondences, :prior_correspondence, null: false, foreign_key: { to_table: :correspondences }, index: false, comment: "Foreign key to Coreespondences table"
    add_index :correspondences, :prior_correspondence_id, algorithm: :concurrently
  end
end
