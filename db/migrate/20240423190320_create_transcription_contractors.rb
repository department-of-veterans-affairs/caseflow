class CreateTranscriptionContractors < ActiveRecord::Migration[6.0]
  def change
    create_table :transcription_contractors do |t|
      t.string :qat_name, null: false, comment: "The qat contract house name"
      t.string :qat_directory, null: false, comment: "The qat contract house box.com folder full path"
      t.string :qat_poc, comment: "The qat contract house poc name"
      t.string :qat_phone, comment: "The qat contract house contact phone number"
      t.string :qat_email, comment: "The qat contract house contact email address"
      t.boolean :qat_stop, default: false, null: false, comment: "Work Stoppage flag to indicate if a qat is available or not to take work"
      t.integer :previous_goal, default: 0, comment: "The previous weeks goal of hearings to send for transcribing"
      t.integer :current_goal, default: 0, comment: "The current weeks goal of hearings to send for transcribing"
      t.boolean :inactive, default: false, null: false, comment: "Indicates if the qat is active or not inactive equates to not displayed in ui"

      t.timestamps
    end

    add_index :transcription_contractors, :inactive, name: "index_transcription_contractors_on_inactive"
  end
end
