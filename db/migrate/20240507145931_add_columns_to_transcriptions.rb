class AddColumnsToTranscriptions < Caseflow::Migration
  def change
    add_column :transcriptions, :transcription_contractor_id, :bigint
    add_column :transcriptions, :created_by_id, :bigint
    add_column :transcriptions, :transcription_status, :string, comment: "Possible values: 'unassigned', 'in_transcription', 'completed', 'completed_overdue'"
    add_column :transcriptions, :updated_by_id, :bigint
    add_column :transcriptions, :deleted_at, :datetime, comment: "acts_as_paranoid in the model"

    add_foreign_key :transcriptions, :transcription_contractors, column: "transcription_contractor_id", validate: false
    add_foreign_key :transcriptions, :users, column: "created_by_id", validate: false
    add_foreign_key :transcriptions, :users, column: "updated_by_id", validate: false
  end
end
