class CreateTranscriptionContractors < ActiveRecord::Migration[6.0]
  def change
    create_table :transcription_contractors do |t|
      t.string :name, null: false, comment: "The contract house name"
      t.string :directory, null: false, comment: "The contract house box.com folder full path"
      t.string :poc, null: false, comment: "The contract house poc name"
      t.string :phone, null: false, comment: "The contract house contact phone number"
      t.string :email, null: false, comment: "The contract house contact email address"
      t.boolean :is_available_for_work, default: false, null: false, comment: "Work Stoppage flag to indicate if a is available or not to take work"
      t.integer :previous_goal, default: 0, comment: "The previous weeks goal of hearings to send for transcribing"
      t.integer :current_goal, default: 0, comment: "The current weeks goal of hearings to send for transcribing"
      t.boolean :inactive, default: false, null: false, comment: "Indicates if the contractor is active or not inactive equates to not displayed in ui"

      t.timestamps
    end

    add_index :transcription_contractors, :inactive, name: "index_transcription_contractors_on_inactive"
  end
end
