class CreateCorrespondenceResponseLetters < ActiveRecord::Migration[6.1]
  def change
    create_table :correspondence_response_letters do |t|
      t.integer :correspondence_id, comment: "Foreign key on correspondences table"
      t.datetime :date_sent, comment: "Date at the time of sending correspondence response letters"
      t.string :type, null: false, comment: "Correspondence response letter type"
      t.string :title, null: false, comment: "Correspondence response letters title"
      t.string :subcategory, comment: "The subcategory selected for the correspondence response letter "
      t.string :reason, comment: "Reason for selecting the response letter"
      t.integer :response_window, comment: "The response window selected for the correspondence response letter"
      t.integer :user_id, comment: "The user who has created correspondence response letter"
      t.timestamps
    end
  end
end
