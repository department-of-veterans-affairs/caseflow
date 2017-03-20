class CreateDocumentUsers < ActiveRecord::Migration
  def change
    create_table :document_users do |t|
      t.belongs_to :document, null: false
      t.belongs_to :user, null: false

      t.datetime   :first_viewed_at
    end

    add_index(:document_users, [:document_id, :user_id], unique: true)
  end
end
