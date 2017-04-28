class CreateJoinTableDocumentsTags < ActiveRecord::Migration
  def change
    create_table :documents_tags, :id => false do |t|
      t.index [:document_id, :tag_id]
      t.index [:tag_id, :document_id]
    end
  end
end
