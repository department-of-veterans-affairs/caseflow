class CreateMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :messages do |t|
      t.string :text, comment: "The message"
      t.timestamp :read_at, comment: "When the message was read"
      t.integer :user_id, null: false, comment: "The user for whom the message is intended"

      t.timestamps
    end
  end
end
