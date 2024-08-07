# frozen_string_literal: true

require 'aws-sdk-s3'
class VaBoxUploadJob < CaseflowJob
  queue_as :low_priority
  include Hearings::SendTranscriptionIssuesEmail

  S3_BUCKET = "vaec-appeals-caseflow"
  MAX_RETRIES = 3

  def perform(file_info, box_folder_id)
    box_service = ExternalApi::VaBoxService.new(
      client_secret: ENV['BOX_CLIENT_SECRET'],
      client_id: ENV['BOX_CLIENT_ID'],
      enterprise_id: ENV['BOX_ENTERPRISE_ID'],
      private_key: ENV['BOX_PRIVATE_KEY'],
      passphrase: ENV['BOX_PASS_PHRASE']
    )
    box_service.fetch_access_token

    file_info[:hearings].each do |hearing|
      retries = 0
      begin
        transcription_package = find_transcription_package(hearing)
        unless transcription_package
          error_details = { error: { type: "transcription_package", message: "Transcription package not found for hearing ID: #{hearing[:hearing_id]}" }, provider: "Box" }
          send_transcription_issues_email(error_details)
          next
        end

        # Store previous state
        previous_state = transcription_package.attributes.except("status")

        file_path = transcription_package.aws_link_zip
        contractor_name = file_info[:contractor_name]
        child_folder_id = box_service.get_child_folder_id(box_folder_id, contractor_name)

        unless child_folder_id
          error_details = { error: { type: "child_folder_id", message: "Child folder ID not found for contractor name: #{contractor_name}" }, provider: "Box" }
          send_transcription_issues_email(error_details)
          next
        end

        # Download file from S3
        local_file_path = download_file_from_s3(file_path)

        upload_to_box(box_service, local_file_path, child_folder_id, transcription_package)
      rescue StandardError => e
        retries += 1
        if retries <= MAX_RETRIES
          Rails.logger.warn("Retrying VaBoxUploadJob due to error: #{e.message}. Attempt #{retries} of #{MAX_RETRIES}.")
          retry
        else
          handle_error(e, transcription_package, previous_state)
          error_details = { error: { type: "upload", message: e.message }, provider: "Box" }
          send_transcription_issues_email(error_details)
        end
      end
    end
  end

  private

  def find_transcription_package(hearing)
    if hearing[:hearing_type] == "LegacyHearing"
      TranscriptionPackageLegacyHearing.find_by(legacy_hearing_id: hearing[:hearing_id])&.transcription_package
    else
      TranscriptionPackageHearing.find_by(hearing_id: hearing[:hearing_id])&.transcription_package
    end
  end

  def download_file_from_s3(s3_path)
    local_path = Rails.root.join('tmp', 'transcription_files', File.basename(s3_path))
    Caseflow::S3Service.fetch_file(s3_path, local_path)
    Rails.logger.info("File successfully downloaded from S3: #{local_path}")
    local_path
  end

  def upload_to_box(box_service, file_path, folder_id, transcription_package)
    box_service.public_upload_file(file_path, folder_id)
    Rails.logger.info("File successfully uploaded to Box folder ID: #{folder_id}")
    transcription_package.update!(
      date_upload_box: Time.current,
      status: 'Successful Upload (BOX)',
      task_number: file_info[:work_order_name],
      expected_return_date: file_info[:return_date],
      updated_by_id: RequestStore[:current_user].id
    )
  end

  def handle_error(error, transcription_package, previous_state)
    Rails.logger.error("Failed to upload transcription package: #{error.message}")
    rollback_to_previous_state(transcription_package, previous_state)
  end

  def rollback_to_previous_state(transcription_package, previous_state)
    Rails.logger.info("Rolling back transcription package to previous state")
    transcription_package.update!(previous_state.merge(status: 'failed'))
  end
end





