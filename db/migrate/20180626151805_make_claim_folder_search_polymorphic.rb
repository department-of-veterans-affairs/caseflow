class MakeClaimFolderSearchPolymorphic < ActiveRecord::Migration[5.1]
  def change
    add_column :claims_folder_searches, :appeal_type, :string
  end
end
