# frozen_string_literal: true

class Hearings::VaBoxUploadJob < CaseflowJob
  queue_as :low_priority
  S3_BUCKET = "vaec-appeals-caseflow"
  include Hearings::SendTranscriptionIssuesEmail

  class BoxUploadError < StandardError; end

  # retry_on StandardError, wait: :exponentially_longer do |job, exception|
  #   job.cleanup_tmp_files
  #   error_details = { error: { type: "upload", message: exception.message }, provider: "Box" }
  #   job.send_transcription_issues_email(error_details) unless job.email_sent?(:upload)
  #   job.mark_email_sent(:upload)
  #   fail BoxUploadError
  # end

  def perform(file_info, box_folder_id)
    @all_paths = []
    @email_sent_flags = { transcription_package: false, child_folder_id: false, upload: false }

    box_service = VaBoxService.new

    file_info[:hearings].each do |hearing|
      begin
        transcription_package = find_transcription_package(hearing)
        unless transcription_package
          error_details = {
            error: {
              type: "transcription_package",
              message: "Transcription package not found for hearing ID: #{hearing[:hearing_id]}"
            },
            provider: "Box"
          }
          send_transcription_issues_email(error_details) unless email_sent?(:transcription_package)
          mark_email_sent(:transcription_package)
          next
        end

        s3_file_path = transcription_package.aws_link_zip
        contractor_name = file_info[:contractor_name]
        contractor = TranscriptionContractor.find_by_name(file_info[:contractor_name])

        child_folder_id = false
        if contractor
          child_folder_id = box_service.get_child_folder_id(box_folder_id, contractor.directory)
        end

        unless child_folder_id
          error_details = {
            error: {
              type: "child_folder_id",
              message: "Child folder ID not found for contractor name: #{contractor_name}"
            },
            provider: "Box"
          }
          send_transcription_issues_email(error_details) unless email_sent?(:child_folder_id)
          mark_email_sent(:child_folder_id)
          break
        end

        # Download file from S3
        local_file_path = download_file_from_s3(s3_file_path)

        upsert_to_box(box_service, local_file_path, child_folder_id, transcription_package, file_info, hearing)

        # Update transcription files after successful upload
        update_transcription_files(hearing)
      rescue StandardError => error
        log_error(error, extra: { transcription_package_id: transcription_package&.id })
        error_details = { error: { type: "upload", message: error.message }, provider: "Box" }
        send_transcription_issues_email(error_details) unless email_sent?(:upload)
        mark_email_sent(:upload)
        next
      end
    end
  end

  private

  def find_transcription_package(hearing)
    TranscriptionPackageHearing.find_by(
      hearing_type: hearing[:hearing_type],
      hearing_id: hearing[:hearing_id]
    )&.transcription_package
  end

  def download_file_from_s3(s3_path)
    local_path = Rails.root.join("tmp", "transcription_files", File.basename(s3_path))
    S3Service.fetch_file(s3_path, local_path)
    @all_paths << local_path
    Rails.logger.info("File successfully downloaded from S3: #{local_path}")
    local_path
  end

  # rubocop:disable Metrics/ParameterLists
  def upsert_to_box(box_service, local_file_path, child_folder_id, transcription_package, file_info, hearing)
    expected_return_date = format_return_date(file_info[:return_date])
    ActiveRecord::Base.transaction do
      box_service.upload_file(local_file_path, child_folder_id)
      Rails.logger.info("File successfully uploaded to Box folder ID: #{child_folder_id}")
      transcription_package.update!(
        date_upload_box: Time.current,
        status: "Successful Upload (BOX)",
        task_number: file_info[:work_order_name],
        expected_return_date: expected_return_date,
        updated_by_id: RequestStore[:current_user].id
      )

      transcription_package.transcription_package_hearings.each do |transcription_package_hearing|
        transcription_package_hearing.hearing.transcriptions.each do |transcription|
          transcription.update!(
            expected_return_date: expected_return_date,
            sent_to_transcriber_date: Time.current,
            task_number: file_info[:work_order_name],
            transcriber: file_info[:contractor_name],
            transcription_contractor_id: transcription_package.contractor_id,
            updated_by_id: RequestStore[:current_user].id
          )
        end
      end
    end
  end
  # rubocop:enable Metrics/ParameterLists

  def format_return_date(return_date)
    parts = return_date.split('/')
    "#{parts[2]}-#{parts[0]}-#{parts[1]}".to_date
  end

  def update_transcription_files(hearing)
    TranscriptionFile.where(
      hearing_id: hearing[:hearing_id], hearing_type: hearing[:hearing_type]
    ).update_all(
      date_upload_box: Time.current,
      updated_by_id: RequestStore[:current_user].id
    )
  end

  def cleanup_tmp_files
    @all_paths&.each { |path| File.delete(path) if File.exist?(path) }
    Rails.logger.info("Cleaned up the following files from tmp: #{@all_paths}")
  end

  def email_sent?(type)
    @email_sent_flags[type]
  end

  def mark_email_sent(type)
    @email_sent_flags[type] = true
  end
end
