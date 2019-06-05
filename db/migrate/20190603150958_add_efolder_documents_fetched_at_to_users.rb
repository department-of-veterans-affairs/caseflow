class AddEfolderDocumentsFetchedAtToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :efolder_documents_fetched_at, :datetime, comment: "Date when efolder documents were cached in s3 for this user"
  end
end
