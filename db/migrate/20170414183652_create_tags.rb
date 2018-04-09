class CreateTags < ActiveRecord::Migration[5.1]
  def change
    create_table :tags do |t|
      t.string :text
      t.integer :document_id

      t.timestamps null: false
    end
  end
end
