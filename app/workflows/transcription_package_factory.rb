# frozen_string_literal: true

class TranscriptionPackageFactory
  def initialize(transcription_package)
    @transcription_package = TranscriptionPackage.create!(
      aws_link_zip: transcription_package[:aws_link_zip],
      aws_link_work_order: transcription_package[:aws_link_work_order],
      created_by_id: transcription_package[:created_by_id],
      returned_at: transcription_package[:returned_at],
      task_number: transcription_package[:task_name],
      date_upload_box: transcription_package[:date_upload_box],
      date_upload_aws: transcription_package[:date_upload_aws]
    )
  end
end
