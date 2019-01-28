class AddUploadedToVbmsAtToDecisionDocument < ActiveRecord::Migration[5.1]
  def change
  	add_column :decision_documents, :uploaded_to_vbms_at, :datetime
  end
end
