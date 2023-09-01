class AddDeletedAtToConferenceLinks < Caseflow::Migration
  def change
    add_column :conference_links, :deleted_at, :datetime, comment: "Neccessary column for soft delete functionality."
    add_index :conference_links, :deleted_at
  end
end
