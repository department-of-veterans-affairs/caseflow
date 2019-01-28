class AddAsyncableColumnsToDecisionDocument < ActiveRecord::Migration[5.1]
  def change
    add_column :decision_documents, :submitted_at, :datetime
    add_column :decision_documents, :attempted_at, :datetime
    add_column :decision_documents, :processed_at, :datetime
    add_column :decision_documents, :error, :string
  end
end
