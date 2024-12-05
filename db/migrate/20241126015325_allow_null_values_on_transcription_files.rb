class AllowNullValuesOnTranscriptionFiles < ActiveRecord::Migration[6.1]
  def change
    change_column_null :transcription_files, :hearing_id, true
    change_column_null :transcription_files, :hearing_type, true
    change_column_null :transcription_files, :docket_number, true
  end
end
