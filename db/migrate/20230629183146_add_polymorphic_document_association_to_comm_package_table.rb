class AddPolymorphicDocumentAssociationToCommPackageTable < ActiveRecord::Migration[5.2]
  def change
    remove_index :vbms_communication_packages, :vbms_uploaded_document_id

    add_reference :vbms_communication_packages, :document_mailable_via_pacman, polymorphic: true, index: false

    VbmsCommunicationPackage.find_each do |vcp|
      unless vcp.vbms_uploaded_document_id.nil?
        vcp.update_attribute(:document_mailable_via_pacman_type, "VbmsUploadedDocument")
        vcp.document_mailable_via_pacman_id = vcp.vbms_uploaded_document_id
      end
    end

    safety_assured { remove_column :vbms_communication_packages, :vbms_uploaded_document_id }
  end
end
