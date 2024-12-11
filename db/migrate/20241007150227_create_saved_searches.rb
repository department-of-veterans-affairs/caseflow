class CreateSavedSearches < ActiveRecord::Migration[6.1]
  def change
    create_table :saved_searches do |t|
      t.string :name
      t.text :description
      t.references :user , foreign_key: true
      t.json :saved_search, default: {}, comment: "saved search data to store for the generate task report"

      t.timestamps
    end
  end
end
