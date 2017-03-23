class CreateDocumentViews < ActiveRecord::Migration
  def change
    create_table :document_views do |t|
      t.belongs_to :document, null: false
      t.belongs_to :user, null: false

      t.datetime   :first_viewed_at
    end

    add_index(:document_views, [:document_id, :user_id], unique: true)
  end
end
