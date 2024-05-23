# frozen_string_literal: true

class TranscriptionPackageFactory
  def initialize(task_name, created_by_id, returned_at)
    @transcription_package = TranscriptionPackage.create!(
      created_by_id: created_by_id,
      returned_at: returned_at,
      task_number: task_name
    )
  end
end
