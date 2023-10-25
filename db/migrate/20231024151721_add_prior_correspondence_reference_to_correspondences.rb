class AddPriorCorrespondenceReferenceToCorrespondences < Caseflow::Migration
  disable_ddl_transaction!

  def change
    add_reference :correspondences, :prior_correspondence, null: false, foreign_key: { to_table: :correspondences }, index: false, comment: "Foreign key to Correspondences table"
  end
end
