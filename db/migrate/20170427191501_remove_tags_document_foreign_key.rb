class RemoveTagsDocumentForeignKey < ActiveRecord::Migration
  def change
    remove_column :tags, :document_id
  end
end
