class AddDeletedAtToConferenceLinks < Caseflow::Migration
  disable_ddl_transaction!

  def change
    add_column :conference_links, :deleted_at, :datetime, comment: "Needed column to make use of the paranoia gem."
    add_index :conference_links, :deleted_at, algorithm: :concurrently
  end
end
