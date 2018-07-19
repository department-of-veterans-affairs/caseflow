class CreateOrganizationsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :organizations do |t|
      t.string "type"
      t.string "name"
      t.string "role"
      t.string "function"
      t.string "url"
    end
  end
end
