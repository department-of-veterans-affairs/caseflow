class CreateClaimsFolderSearches < ActiveRecord::Migration[5.1]
  def change
    create_table :claims_folder_searches do |t|
      t.belongs_to :user
      t.belongs_to :appeal

      t.string :query
      t.datetime :created_at
    end
  end
end
