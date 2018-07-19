class CreateOrganizationsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :organizations do |t|
      t.string :type
      t.string :name
      t.string :role
      t.string :feature
      t.string :url
      t.string :participant_id
    end
  end
end
