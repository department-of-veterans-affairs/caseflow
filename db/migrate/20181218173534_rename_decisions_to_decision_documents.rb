class RenameDecisionsToDecisionDocuments < ActiveRecord::Migration[5.1]
  def change
    rename_table :decisions, :decision_documents
  end
end
