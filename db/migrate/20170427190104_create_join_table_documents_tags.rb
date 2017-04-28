class CreateJoinTableDocumentsTags < ActiveRecord::Migration
  def change
    create_join_table :documents, :tags do |t|
      t.index [:document_id, :tag_id]
      t.index [:tag_id, :document_id]
    end
  end
end
