class AddColumnsToTranscriptions < Caseflow::Migration
  def change
    add_column :transcriptions, :transcription_contractor_id, :int
    add_column :transcriptions, :created_by_id, :int
    add_column :transcriptions, :transcription_status, :string, comment: "Possible values: 'unassigned', 'in_transcription', 'completed', 'completed_overdue'"
    add_column :transcriptions, :updated_by_id, :int
    add_column :transcriptions, :deleted_at, :datetime, comment: "acts_as_paranoid in the model"
  end
end
