class UploadTranscriptionPackageJob < CaseflowJob
  queue_as :default

  def perform(transcription_file_id, file_path, folder_id)
    transcription_file = TranscriptionFile.find(transcription_file_id)
    box_service = ExternalApi::BoxService.new(box_client_id: ENV['BOX_CLIENT_ID'], box_client_secret: ENV['BOX_CLIENT_SECRET'], box_enterprise_id: ENV['BOX_ENTERPRISE_ID'], box_jwt_private_key: ENV['BOX_JWT_PRIVATE_KEY'], box_jwt_private_key_password: ENV['BOX_JWT_PRIVATE_KEY_PASSWORD'], box_jwt_public_key_id: ENV['BOX_JWT_PUBLIC_KEY_ID'])

    retries = 3
    begin
      file_size = File.size(file_path)
      if file_size > 50 * 1024 * 1024
        file = box_service.upload_large_file(file_path, folder_id)
      else
        file = box_service.upload_file(file_path, folder_id)
      end

      # Update the database with the required information
      transcription_file.update(
        aws_link: file.shared_link.url, # Update the AWS link if the file is also stored in AWS
        date_upload_box: Time.now, # Update the timestamp when the file was added to Box
        file_status: 'Successful upload (Box)' # Update the file status
      )
    rescue StandardError => error
      if retries > 0
        retries -= 1
        log_error(error)
        retry
      else
        handle_failure(transcription_file)
      end
    end
  end

  def handle_failure(error, transcription_file_id, file_path, folder_id)
    transcription_file = TranscriptionFile.find(transcription_file_id)
    box_service = ExternalApi::BoxService.new(box_client_id: ENV['BOX_CLIENT_ID'], box_client_secret: ENV['BOX_CLIENT_SECRET'], box_enterprise_id: ENV['BOX_ENTERPRISE_ID'], box_jwt_private_key: ENV['BOX_JWT_PRIVATE_KEY'], box_jwt_private_key_password: ENV['BOX_JWT_PRIVATE_KEY_PASSWORD'], box_jwt_public_key_id: ENV['BOX_JWT_PUBLIC_KEY_ID'])

    # Delete the file from Box
    box_service.delete_file(file_path, folder_id)

    # Revert changes made to the transcription file
    transcription_file.update(
      aws_link: nil, # Remove the AWS link
      date_upload_box: nil, # Remove the timestamp when the file was added to Box
      file_status: 'Failed upload (Box)' # Update the file status
    )

    # Log the error
    log_error('Failed upload (Box): ' + error.message)
  end
end


# The provided code and implementation notes suggest that the following additional acceptance criteria (A.C.) need to be met:

#1. The job should handle error conditions:

# If the upload of the Transcription Package fails, it should retry.
# If the upload fails after 3 retries, a notification should be sent and the following actions should be taken:
# Destroy the Transcription Package, BoM, Appeal Zip(s), and Work Order.
# Roll back database updates.
# Send Appeals back to Unassigned.
# Exit the workflow.
#2. The job should update the database with required information for the creation and upload of the Transcription Package. This might involve the use of temporary tables and caching.

#3. Upon completion, the job should kick off the next job in the workflow.

#4. The job should interact with the Box API to upload the Transcription Package. This involves:

# Fetching and refreshing access tokens.
# Handling different file sizes (smaller or larger than 50MB).
# Updating the transcription_files table with relevant information.
# Sending error emails to the VA Operations Team if the upload to the Box endpoint fails.
#5. The job should use the ExternalApi::BoxService class for interacting with the Box API. This class should be able to:

# Fetch and refresh access tokens.
# Upload the Transcription Package to the Box endpoint.
# Handle error conditions and send notifications if necessary.
