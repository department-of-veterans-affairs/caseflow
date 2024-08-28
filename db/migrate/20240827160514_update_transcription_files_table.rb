class UpdateTranscriptionFilesTable < Caseflow::Migration
  def change
    add_column :transcription_files, :recording_task_number, :string, comment: "Number associated with recording, is the created id from the recording system"
    add_column :transcription_files, :recording_transcriber, :string, comment: "Contractor who created the closed caption transcription for the recording; i.e, 'Webex'"
    add_column :transcription_files, :date_returned_box, :datetime, comment: "Timestamp when file was added to the Box.com return folder by a QAT contractor. Used for performance metrics."

    safety_assured do
      rename_column :transcription_files, :date_receipt_webex, :date_receipt_recording
    end

    change_column_null :transcription_files, :docket_number, false
    change_column_null :transcription_files, :hearing_id, false
    change_column_null :transcription_files, :hearing_type, false
  end
end
