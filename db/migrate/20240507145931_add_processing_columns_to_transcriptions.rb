class AddProcessingColumnsToTranscriptions < Caseflow::Migration
  disable_ddl_transaction!

  def change
    add_column :transcriptions, :transcription_contractor_id, :int
    add_column :transcriptions, :created_by_id, :int
    add_column :transcriptions, :transcription_status, :string, comment: "Possible values: 'unassigned', 'in_transcription', 'completed', 'completed_overdue'"
    add_column :transcriptions, :updated_by_id, :int
    add_column :transcriptions, :deleted_at, :datetime, comment: "acts_as_paranoid in the model"

    add_index :transcriptions, [:transcription_contractor_id], name: "index_transcriptions_on_transcription_contractor_id", algorithm: :concurrently
    add_index :transcriptions, [:deleted_at], name: "index_transcriptions_on_deleted_at", algorithm: :concurrently
  end
end
