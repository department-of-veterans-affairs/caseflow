class CreateDocumentView < ActiveRecord::Migration
  def change
    create_table :document_view do |t|
      t.belongs_to :document, null: false
      t.belongs_to :user, null: false

      t.datetime   :first_viewed_at
    end

    add_index(:document_view, [:document_id, :user_id], unique: true)
  end
end
