class CreateAnnotations < ActiveRecord::Migration
  def change
    create_table :annotations do |t|
      t.belongs_to :document, null: false
      t.string :comment
      t.integer :page
      t.integer :x_location
      t.integer :y_location
    end
    add_index(:annotations, :document_id)
    add_index(:annotations, :page)
  end
end
