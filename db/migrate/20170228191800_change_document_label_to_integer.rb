class ChangeDocumentLabelToInteger < ActiveRecord::Migration
  def change
    remove_column :documents, :label
    add_column :documents, :label, :integer
  end
end
