class AddIndexToPolymorphicDocumentAssociationInCommPackageTable < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :vbms_communication_packages,
              [:document_mailable_via_pacman_type, :document_mailable_via_pacman_id],
              name: "index_vbms_communication_packages_on_pacman_document_id",
              algorithm: :concurrently
  end
end
