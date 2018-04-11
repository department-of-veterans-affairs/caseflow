class RemoveTagsDocumentForeignKey < ActiveRecord::Migration[5.1]
  def change
    remove_column :tags, :document_id
  end
end
