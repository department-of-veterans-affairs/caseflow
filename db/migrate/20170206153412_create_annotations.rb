class CreateAnnotations < ActiveRecord::Migration
  def change
    create_table :annotations do |t|
      t.belongs_to :document, null: false
      t.string :comment
      t.integer :page
      t.integer :x
      t.integer :y
    end
    add_index(:annotations, :document_id)
  end
end
