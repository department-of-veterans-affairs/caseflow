class UploadTranscriptionPackageJob < CaseflowJob
  queue_as :default

  def perform(transcription_file_id, file_path, folder_id)
    transcription_file = TranscriptionFile.find(transcription_file_id)

    client = OAuth2::Client.new(ENV['BOX_CLIENT_ID'], ENV['BOX_CLIENT_SECRET'], site: 'https://api.box.com', token_url: '/oauth2/token')
    token = client.client_credentials.get_token

    retries = 3
    begin
      file_size = File.size(file_path)
      if file_size > 50 * 1024 * 1024
        # Upload large file
        response = token.post('/2.0/files/upload_sessions', body: { file_size: file_size, name: File.basename(file_path), parent: { id: folder_id } })
        upload_url = response.parsed['upload_url']
        # TODO: Split the file into parts and upload each part to the upload URL
      else
        # Upload regular file
        response = token.post('/2.0/files/content', body: { name: File.basename(file_path), parent: { id: folder_id } }, headers: { 'Content-Type' => 'multipart/form-data' })
      end

      file = response.parsed

      # Update the database with the required information
      transcription_file.update(
        aws_link: file['shared_link']['url'], # Update the AWS link if the file is also stored in AWS
        date_upload_box: Time.now, # Update the timestamp when the file was added to Box
        file_status: 'Successful upload (Box)' # Update the file status
      )
    rescue StandardError => error
      if retries > 0
        retries -= 1
        log_error(error)
        retry
      else
        handle_failure(error, transcription_file_id, file_path, folder_id)
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
      date_upload_box: nil, # Remove the timestamp when the file was added to Box
      file_status: 'Failed upload (Box)' # Update the file status
    )

    # Log the error
    log_error('Failed upload (Box): ' + error.message)

    # Send an email about the error
    TranscriptionFileIssuesMailer.issue_notification(
      error: { type: 'upload', explanation: error.message },
      provider: 'Box',
      docket_number: transcription_file.docket_number,
      appeal_id: transcription_file.appeal_id
    ).deliver_now
  end
end

# TranscriptionPackage.perform_later(args)

# Here are the Acceptance Criteria (AC) based on the provided description and implementation notes:
#
# 1. Create a new workflow job to POST a Transcription Package to box.com.
# 2. The job should use parameters passed in from the 'Transcription Package' job.
# 3. The job should upload the Transcription Package file to BOX.
# 4. The job should handle error conditions:
#    1. If the upload fails, it should retry.
#    2. If the upload fails after a certain number of retries, it should:
#       1. Destroy the Transcription Package.
#       2. Destroy the BoM.
#       3. Destroy Appeal Zip(s).
#       4. Destroy the Work Order.
#       5. Roll back any database updates.
#       6. Send Appeals back to Unassigned.
#       7. Exit the workflow.
# 5. The job should update the database with required information for the creation and upload of the Transcription Package.
# 6. Upon completion, the job should kickoff the next job.
# 7. The names for the transcription zip file should be passed in as parameters.
# 8. The AWS S3 Bucket is considered as the transcription_text S3 bucket.
# 9. Caseflow should pull the Transcription Package from the AWS transcript_text S3 bucket.
# 10. Caseflow should upload the Transcription Package to the BOX endpoint.
# 11. A new gem should be installed for communicating with BOX.
# 12. Caseflow should upload the Transcription Package Master ZIP file to a specified Endpoint.
# 13. Caseflow should update the transcription_files table with:
#     1. file_status of "Success or Failure of Upload to box.com".
#     2. file_name.
#     3. date_upload_aws.
#     4. created_by_id.
#     5. file_type.
# 14. If Caseflow is unable to upload to the box.com endpoint, it should send error emails to the VA Operations Team.


# *** NOT DONE YET ***

# 1. The job should use parameters passed in from the 'Transcription Package' job.
# 2. If the upload fails after a certain number of retries, it should:
#    1. Destroy the Transcription Package.
#    2. Destroy the BoM.
#    3. Destroy Appeal Zip(s).
#    4. Destroy the Work Order.
#    5. Roll back any database updates.
#    6. Send Appeals back to Unassigned.
#    7. Exit the workflow.
# 3. Upon completion, the job should kickoff the next job. *** DONE ***
# 4. The names for the transcription zip file should be passed in as parameters.
# 5. The AWS S3 Bucket is considered as the transcription_text S3 bucket.
# 6. Caseflow should pull the Transcription Package from the AWS transcript_text S3 bucket.
# 7. A new gem should be installed for communicating with BOX.
# 8. Caseflow should upload the Transcription Package Master ZIP file to a specified Endpoint.
# 9. Caseflow should update the transcription_files table with:
#    1. file_name.
#    2. created_by_id.
#    3. file_type.
# 10. If Caseflow is unable to upload to the box.com endpoint, it should send error emails to the VA Operations Team.

