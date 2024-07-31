# frozen_string_literal: true

require 'aws-sdk-s3'
require 'active_job'

class VaBoxUploadJob < ActiveJob::Base
  queue_as :default

  MAX_RETRIES = 3
  S3_BUCKET = "vaec-appeals-caseflow"

  def perform(transcription_package_id, s3_bucket, s3_key, box_folder_id)
    transcription_package = TranscriptionPackage.find(transcription_package_id)
    s3_client = Aws::S3::Client.new
    box_service = ExternalApi::VaBoxService.new(
      client_secret: ENV['BOX_CLIENT_SECRET'],
      client_id: ENV['BOX_CLIENT_ID'],
      enterprise_id: ENV['BOX_ENTERPRISE_ID'],
      private_key: ENV['BOX_PRIVATE_KEY'],
      passphrase: ENV['BOX_PASSPHRASE']
    )

    file_path = download_from_s3(s3_client, s3_bucket, s3_key)
    upload_to_box(box_service, file_path, box_folder_id)

    update_database(transcription_package)
    kickoff_next_job
  rescue StandardError => e
    handle_error(e, transcription_package)
  ensure
    File.delete(file_path) if file_path && File.exist?(file_path)
  end

  private

  def download_from_s3(s3_client, bucket, key)
    file_path = "/tmp/#{File.basename(key)}"
    s3_client.get_object(response_target: file_path, bucket: bucket, key: key)
    file_path
  end

  def upload_to_box(box_service, file_path, folder_id)
    retries ||= 0
    box_service.fetch_access_token
    box_service.public_upload_file(file_path, folder_id)
  rescue StandardError => e
    retries += 1
    retry if retries < MAX_RETRIES
    raise e
  end

  def update_database(transcription_package)
    transcription_package.update!(
      status: 'Successful Upload (BOX)',
      date_upload_box: Time.now,
      updated_at: Time.now,
      updated_by_id: current_user.id # Assuming you have access to the current user's ID
    )
  end

  def kickoff_next_job
    # Logic to kickoff the next job
  end

  def handle_error(error, transcription_package)
    Rails.logger.error("Failed to upload transcription package: #{error.message}")
    transcription_package.update!(status: 'failed')
    # Perform cleanup and rollback operations
    cleanup_resources(transcription_package)
    send_error_notification(error)
  end

  def cleanup_resources(transcription_package)
    # Logic to destroy resources and rollback DB updates
  end

  def send_error_notification(error)
    # Logic to send error notification emails
    ErrorMailer.upload_failed(error).deliver_now
  end
end

# ? What does it mean to cleanup resources? What resources?
# ? What object is being passed to decide where each package is being sent too?
# ? Do we have a test s3 bucket?
# ? What job are we kicking off next?


