class AddMessageTypeToMessages < ActiveRecord::Migration[5.1]
  def up
    add_column :messages, :message_type, :string, comment: "The type of event that caused this message to be created"
    safety_assured do
      execute "UPDATE messages SET message_type='job_note_added' WHERE text LIKE 'A new note has been added %'"
    end
  end

  def down
    remove_column :messages, :message_type
  end
end
