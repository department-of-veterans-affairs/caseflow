class AddDeletedAtToConferenceLinks < ActiveRecord::Migration[5.2]
  def change
    add_column :conference_links, :deleted_at, :datetime
    add_index :conference_links, :deleted_at
  end
end
