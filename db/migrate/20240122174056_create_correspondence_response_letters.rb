class CreateCorrespondenceResponseLetters < ActiveRecord::Migration[5.2]
  def change
    create_table :correspondence_response_letters do |t|
      t.integer :correspondence_id
      t.datetime :date_sent
      t.string :type
      t.string :title
      t.string :subcategory
      t.string :reason
      t.integer :response_window
      t.integer :user_id
      t.timestamps
    end
  end
end
