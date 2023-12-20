# Adds columns to the vbms_uploaded_documents table to retain the
# documentVersionReferenceId and documentSeriesReferenceId values that are
# returned once a document is uploaded to VBMS eFolder.
#
# These values can be used to refer to documents and
# update documents via the eFolder API.
#

class AddDocReferenceAndSeriesIdsToVbmsDocumentUploads < Caseflow::Migration
  def up
    add_column :vbms_uploaded_documents,
      :document_version_reference_id,
      :string,
      comment: "UUID that is provided by eFolder that represents the specific version of the document."

    add_column :vbms_uploaded_documents,
      :document_series_reference_id,
      :string,
      comment: "UUID that is provided by eFolder that represents the group of documents" \
        "this document belongs to. Think of a series as a stack of versions."
  end

  def down
    remove_column :vbms_uploaded_documents, :document_version_reference_id
    remove_column :vbms_uploaded_documents, :document_series_reference_id
  end
end
