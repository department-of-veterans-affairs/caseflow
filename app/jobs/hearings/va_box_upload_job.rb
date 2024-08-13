# frozen_string_literal: true

require "aws-sdk-s3"
class VaBoxUploadJob < CaseflowJob
  include Shoryuken::Worker
  queue_as :low_priority
  include Hearings::SendTranscriptionIssuesEmail

  S3_BUCKET = "vaec-appeals-caseflow"

  shoryuken_options retry_intervals: [3.seconds, 30.seconds, 5.minutes, 30.minutes, 2.hours, 5.hours]

  class BoxUploadError < StandardError; end

  retry_on StandardError, wait: :exponentially_longer do |job, exception|
    job.cleanup_tmp_files
    error_details = { error: { type: "upload", message: exception.message }, provider: "Box" }
    job.send_transcription_issues_email(error_details) unless job.email_sent?(:upload)
    job.mark_email_sent(:upload)
    fail BoxUploadError
  end

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
  def perform(file_info, box_folder_id)
    @all_paths = []
    @email_sent_flags = { transcription_package: false, child_folder_id: false, upload: false }
    box_service = ExternalApi::VaBoxService.new(
      client_secret: "sCHkWIqw2H6ewrYjzObSXTtxMDPZpH2o",
      client_id: "em2hg82aw4cgee9bwjii96humn99n813",
      enterprise_id: "828720650",
      private_key: "-----BEGIN ENCRYPTED PRIVATE KEY-----\nMIIFHDBOBgkqhkiG9w0BBQ0wQTApBgkqhkiG9w0BBQwwHAQIoz61tzppMpUCAggA\nMAwGCCqGSIb3DQIJBQAwFAYIKoZIhvcNAwcECMJdArOHrtfGBIIEyMAUJ5NTd6ZS\nvt+hiiQ9FzSCsBsBgBcKaxJvJI+2LYYqiJuZy06NgrSadPTEXruOfAXUfMmIY4vL\nd9RqrizzsOgUPRbG6oAiwuHlCPSeK84mX3PfR4Xglh033HO1yVclcyR/2O6rMS6I\ntkDivRzPIdN/SMKPTP91ZV1k1jQFNkmneW2MyNuBESFSg6aG3Z1fQmJFk7/ACR6n\nzFe8gYjcohK7T/RQhkNDelQir0xHmWIBA55N1+cOWasNUZClrbbj7gobPakTXXin\n3qo/YvE1GYo1sgiucyBx9S4lhsFRmsGeygi5vuukDreOmzCZ5M306oXzKuD7Gj+8\nAGbFs5n+8fRSdb3ZN9EaQF1bDwaZbkMViC+I8c5Ce+7+Q0vB55w47880JZCPTQke\nXOAwGSE6y2ylGl1a26lkNt/4W4dJk6JKF3Mp0MvzTwbAOMEUP5i0UBDWxGEVHf7L\nn6wKpkLLZQnRhSYO24MWuK6n17FLX0eobT7Ih6X1gAgg5BEtsdpMGatrS9uNUb5K\n+GDjGuf134J7wa4tKb+1pE+NTx5C0fRYu6zveEhMCgBOnUUrYVKfnEy/sgcjrOJN\nA8cS34w5ZJ/MqKz0CH8Yd5VnDSHKGxRnumxWwY/eSIvs5yaL0z3aO5qebImzDsOI\niKT6TK+1KXuq5lZyVqATOsMJ6+eLaAHlbhHEGeoRalJXIs2c/7AEoa3EY3nQawsP\nJIvZImffjZM1ESirrnECfq+/QW3fIr3WKXS+yV4xV4/1AVhi4WPvd/xd6KOL/jn3\nuPh4rciaGc0tMODUa36LTKOCUGMVBfVVhtAY/Z2fgwNmXPJXS+Po5W11W1obBu5f\nuOJf2qQ5wOZVK3XFyrXWobmTud7aQDIcMlebfSLyj+BaFsacEWke/nj1BpOygYB7\nY3g827qp0S+4bcDwrwPBQswBBG0bqaUbxXgJc7bfqh9sTAFK7TBOkCgxic17I2d4\ncUMj8C3J4t/IjLgfLRUW7IhddqcctPDEIcpxyqH1L1ZN+UvDb0KC9JnGaBrCotUY\ncsK49cB1AL6VNNf6b08zLJflI3AuQMqjB1kmpa+tlqfGJyc8KuNRFwujdeLEM0aV\n6s3rs7G2GIk9fCPSFBoX3mLBIQvR6fhsXTgAtr4rhKHYuHigMGa2JWHravnyhFUQ\n1+9iAWgNo3esy4CTpYD6+I13fdldBOt4vS+hoepTL+z+xOEMC2JYSDcT9vg5/W25\nma/ku1xGFFLh51tGn4+kdiEF6meYzzrCi1PBs4qv/GMRPwY6theyVsQHu1wEcN7B\n4xlthFMUXdHyvqc6gxmIKthvtCpxCW+5BWJJlIAvqMD/Dpwq2pSmjEJfeJmALSHm\nVS57d4rwGI2gXDwXBqxfWMdh7EGlREobup/ljEQrlbt3TH7yjACnQgGwCnCrLlHl\nTzhVGrONPF1Kagg8oj9SOrjQgIJ7IbjK/QLQEWwNMz3Ywnhmc8ogrG2UuzJLhG3e\n/dLQwmpSnAXCGFPir6ZEz+mdUYHW3g3sYg38U6yetU+RaZ9DWsqVs74w5jS53vG0\nCy/IlVqL4M1wrUVorQyXOux4CI58O9ArbZ/xUEvVloKfD8CzqQdmO9erqyrrDhkL\n04CXKrboQ8djWpNk5MWWuQ==\n-----END ENCRYPTED PRIVATE KEY-----\n",
      passphrase: "320c004d1e36338160c91daf78695309",
    )

    box_service.fetch_access_token

    file_info[:hearings].each_with_index do |hearing, index|
      begin
        transcription_package = find_transcription_package(hearing)
        byebug
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
        local_file_path = transcription_package.aws_link_zip
        contractor_name = file_info[:contractor_name]
        child_folder_id = box_service.get_child_folder_id(box_folder_id, contractor_name)
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
        # local_file_path = download_file_from_s3(file_path)

        if index == 0
          upsert_to_box(box_service, local_file_path, child_folder_id, transcription_package, file_info, hearing)
        else
          create_to_box(box_service, local_file_path, child_folder_id, transcription_package, file_info, hearing)
        end
      rescue StandardError => error
        log_error(error, extra: { transcription_package_id: transcription_package&.id })
        error_details = { error: { type: "upload", message: error.message }, provider: "Box" }
        send_transcription_issues_email(error_details) unless email_sent?(:upload)
        mark_email_sent(:upload)
        next
      end
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength

  private

  def find_transcription_package(hearing)
    if hearing[:hearing_type] == "LegacyHearing"
      TranscriptionPackageLegacyHearing.find_by(legacy_hearing_id: hearing[:hearing_id])&.transcription_package
    else
      TranscriptionPackageHearing.find_by(hearing_id: hearing[:hearing_id])&.transcription_package
    end
  end

  def download_file_from_s3(s3_path)
    local_path = Rails.root.join("tmp", "transcription_files", File.basename(s3_path))
    Caseflow::S3Service.fetch_file(s3_path, local_path)
    @all_paths << local_path
    Rails.logger.info("File successfully downloaded from S3: #{local_path}")
    local_path
  end

  def upsert_to_box(box_service, local_file_path, child_folder_id, transcription_package, file_info, hearing)
    ActiveRecord::Base.transaction do
      box_service.public_upload_file(local_file_path, child_folder_id)
      Rails.logger.info("File successfully uploaded to Box folder ID: #{child_folder_id}")
      transcription_package.update!(
        date_upload_box: Time.current,
        status: "Successful Upload (BOX)",
        task_number: file_info[:work_order_name],
        expected_return_date: file_info[:return_date],
        updated_by_id: RequestStore[:current_user].id
      )
      transcription = Transcription.find_or_initialize_by(task_number: file_info[:work_order_name])
      transcription.update!(
        expected_return_date: file_info[:return_date],
        hearing_id: hearing[:hearing_id],
        sent_to_transcriber_date: Time.current,
        transcriber: file_info[:contractor_name],
        transcription_contractor_id: transcription_package.contractor_id,
        updated_by_id: RequestStore[:current_user].id
      )
    end
  end

  def create_to_box(box_service, local_file_path, child_folder_id, transcription_package, file_info, hearing)
    ActiveRecord::Base.transaction do
      box_service.public_upload_file(local_file_path, child_folder_id)
      Rails.logger.info("File successfully uploaded to Box folder ID: #{child_folder_id}")
      transcription_package.update!(
        date_upload_box: Time.current,
        status: "Successful Upload (BOX)",
        task_number: file_info[:work_order_name],
        expected_return_date: file_info[:return_date],
        updated_by_id: RequestStore[:current_user].id
      )
      transcription = Transcription.new(
        task_number: file_info[:work_order_name],
        expected_return_date: file_info[:return_date],
        hearing_id: hearing[:hearing_id],
        sent_to_transcriber_date: Time.current,
        transcriber: file_info[:contractor_name],
        transcription_contractor_id: transcription_package.contractor_id,
        updated_by_id: RequestStore[:current_user].id
      )
      transcription.save!
    end
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


# file_info = {
#   work_order_name: "#ewrwer34r2rfegvdsrfg",
#   return_date: "12/12/2024",
#   contractor_name: "Genesis Pickup",
#   hearings: [
#     { hearing_id: 1, hearing_type: "Hearing" },
#     { hearing_id: 1, hearing_type: "LegacyHearing" },
#   ],
# }

# box_folder_id = "255974435715"

# user = User.find(1)
# RequestStore[:current_user] = user


# VaBoxUploadJob.perform_now(file_info, box_folder_id)

# service = ExternalApi::VaBoxService.new(
  # client_secret: "sCHkWIqw2H6ewrYjzObSXTtxMDPZpH2o",
  # client_id: "em2hg82aw4cgee9bwjii96humn99n813",
  # enterprise_id: "828720650",
  # private_key: "-----BEGIN ENCRYPTED PRIVATE KEY-----\nMIIFHDBOBgkqhkiG9w0BBQ0wQTApBgkqhkiG9w0BBQwwHAQIoz61tzppMpUCAggA\nMAwGCCqGSIb3DQIJBQAwFAYIKoZIhvcNAwcECMJdArOHrtfGBIIEyMAUJ5NTd6ZS\nvt+hiiQ9FzSCsBsBgBcKaxJvJI+2LYYqiJuZy06NgrSadPTEXruOfAXUfMmIY4vL\nd9RqrizzsOgUPRbG6oAiwuHlCPSeK84mX3PfR4Xglh033HO1yVclcyR/2O6rMS6I\ntkDivRzPIdN/SMKPTP91ZV1k1jQFNkmneW2MyNuBESFSg6aG3Z1fQmJFk7/ACR6n\nzFe8gYjcohK7T/RQhkNDelQir0xHmWIBA55N1+cOWasNUZClrbbj7gobPakTXXin\n3qo/YvE1GYo1sgiucyBx9S4lhsFRmsGeygi5vuukDreOmzCZ5M306oXzKuD7Gj+8\nAGbFs5n+8fRSdb3ZN9EaQF1bDwaZbkMViC+I8c5Ce+7+Q0vB55w47880JZCPTQke\nXOAwGSE6y2ylGl1a26lkNt/4W4dJk6JKF3Mp0MvzTwbAOMEUP5i0UBDWxGEVHf7L\nn6wKpkLLZQnRhSYO24MWuK6n17FLX0eobT7Ih6X1gAgg5BEtsdpMGatrS9uNUb5K\n+GDjGuf134J7wa4tKb+1pE+NTx5C0fRYu6zveEhMCgBOnUUrYVKfnEy/sgcjrOJN\nA8cS34w5ZJ/MqKz0CH8Yd5VnDSHKGxRnumxWwY/eSIvs5yaL0z3aO5qebImzDsOI\niKT6TK+1KXuq5lZyVqATOsMJ6+eLaAHlbhHEGeoRalJXIs2c/7AEoa3EY3nQawsP\nJIvZImffjZM1ESirrnECfq+/QW3fIr3WKXS+yV4xV4/1AVhi4WPvd/xd6KOL/jn3\nuPh4rciaGc0tMODUa36LTKOCUGMVBfVVhtAY/Z2fgwNmXPJXS+Po5W11W1obBu5f\nuOJf2qQ5wOZVK3XFyrXWobmTud7aQDIcMlebfSLyj+BaFsacEWke/nj1BpOygYB7\nY3g827qp0S+4bcDwrwPBQswBBG0bqaUbxXgJc7bfqh9sTAFK7TBOkCgxic17I2d4\ncUMj8C3J4t/IjLgfLRUW7IhddqcctPDEIcpxyqH1L1ZN+UvDb0KC9JnGaBrCotUY\ncsK49cB1AL6VNNf6b08zLJflI3AuQMqjB1kmpa+tlqfGJyc8KuNRFwujdeLEM0aV\n6s3rs7G2GIk9fCPSFBoX3mLBIQvR6fhsXTgAtr4rhKHYuHigMGa2JWHravnyhFUQ\n1+9iAWgNo3esy4CTpYD6+I13fdldBOt4vS+hoepTL+z+xOEMC2JYSDcT9vg5/W25\nma/ku1xGFFLh51tGn4+kdiEF6meYzzrCi1PBs4qv/GMRPwY6theyVsQHu1wEcN7B\n4xlthFMUXdHyvqc6gxmIKthvtCpxCW+5BWJJlIAvqMD/Dpwq2pSmjEJfeJmALSHm\nVS57d4rwGI2gXDwXBqxfWMdh7EGlREobup/ljEQrlbt3TH7yjACnQgGwCnCrLlHl\nTzhVGrONPF1Kagg8oj9SOrjQgIJ7IbjK/QLQEWwNMz3Ywnhmc8ogrG2UuzJLhG3e\n/dLQwmpSnAXCGFPir6ZEz+mdUYHW3g3sYg38U6yetU+RaZ9DWsqVs74w5jS53vG0\nCy/IlVqL4M1wrUVorQyXOux4CI58O9ArbZ/xUEvVloKfD8CzqQdmO9erqyrrDhkL\n04CXKrboQ8djWpNk5MWWuQ==\n-----END ENCRYPTED PRIVATE KEY-----\n",
  # passphrase: "320c004d1e36338160c91daf78695309",
# )

# Folders

# Genesis Pickup

# Ravens Pickup
# def perform(file_info, box_folder_id)
#   @all_paths = []
#   @email_sent_flags = { transcription_package: false, child_folder_id: false, upload: false }
#   box_service = ExternalApi::VaBoxService.new(
#     client_secret: "sCHkWIqw2H6ewrYjzObSXTtxMDPZpH2o",
#     client_id: "em2hg82aw4cgee9bwjii96humn99n813",
#     enterprise_id: "828720650",
#     private_key: "-----BEGIN ENCRYPTED PRIVATE KEY-----\nMIIFHDBOBgkqhkiG9w0BBQ0wQTApBgkqhkiG9w0BBQwwHAQIoz61tzppMpUCAggA\nMAwGCCqGSIb3DQIJBQAwFAYIKoZIhvcNAwcECMJdArOHrtfGBIIEyMAUJ5NTd6ZS\nvt+hiiQ9FzSCsBsBgBcKaxJvJI+2LYYqiJuZy06NgrSadPTEXruOfAXUfMmIY4vL\nd9RqrizzsOgUPRbG6oAiwuHlCPSeK84mX3PfR4Xglh033HO1yVclcyR/2O6rMS6I\ntkDivRzPIdN/SMKPTP91ZV1k1jQFNkmneW2MyNuBESFSg6aG3Z1fQmJFk7/ACR6n\nzFe8gYjcohK7T/RQhkNDelQir0xHmWIBA55N1+cOWasNUZClrbbj7gobPakTXXin\n3qo/YvE1GYo1sgiucyBx9S4lhsFRmsGeygi5vuukDreOmzCZ5M306oXzKuD7Gj+8\nAGbFs5n+8fRSdb3ZN9EaQF1bDwaZbkMViC+I8c5Ce+7+Q0vB55w47880JZCPTQke\nXOAwGSE6y2ylGl1a26lkNt/4W4dJk6JKF3Mp0MvzTwbAOMEUP5i0UBDWxGEVHf7L\nn6wKpkLLZQnRhSYO24MWuK6n17FLX0eobT7Ih6X1gAgg5BEtsdpMGatrS9uNUb5K\n+GDjGuf134J7wa4tKb+1pE+NTx5C0fRYu6zveEhMCgBOnUUrYVKfnEy/sgcjrOJN\nA8cS34w5ZJ/MqKz0CH8Yd5VnDSHKGxRnumxWwY/eSIvs5yaL0z3aO5qebImzDsOI\niKT6TK+1KXuq5lZyVqATOsMJ6+eLaAHlbhHEGeoRalJXIs2c/7AEoa3EY3nQawsP\nJIvZImffjZM1ESirrnECfq+/QW3fIr3WKXS+yV4xV4/1AVhi4WPvd/xd6KOL/jn3\nuPh4rciaGc0tMODUa36LTKOCUGMVBfVVhtAY/Z2fgwNmXPJXS+Po5W11W1obBu5f\nuOJf2qQ5wOZVK3XFyrXWobmTud7aQDIcMlebfSLyj+BaFsacEWke/nj1BpOygYB7\nY3g827qp0S+4bcDwrwPBQswBBG0bqaUbxXgJc7bfqh9sTAFK7TBOkCgxic17I2d4\ncUMj8C3J4t/IjLgfLRUW7IhddqcctPDEIcpxyqH1L1ZN+UvDb0KC9JnGaBrCotUY\ncsK49cB1AL6VNNf6b08zLJflI3AuQMqjB1kmpa+tlqfGJyc8KuNRFwujdeLEM0aV\n6s3rs7G2GIk9fCPSFBoX3mLBIQvR6fhsXTgAtr4rhKHYuHigMGa2JWHravnyhFUQ\n1+9iAWgNo3esy4CTpYD6+I13fdldBOt4vS+hoepTL+z+xOEMC2JYSDcT9vg5/W25\nma/ku1xGFFLh51tGn4+kdiEF6meYzzrCi1PBs4qv/GMRPwY6theyVsQHu1wEcN7B\n4xlthFMUXdHyvqc6gxmIKthvtCpxCW+5BWJJlIAvqMD/Dpwq2pSmjEJfeJmALSHm\nVS57d4rwGI2gXDwXBqxfWMdh7EGlREobup/ljEQrlbt3TH7yjACnQgGwCnCrLlHl\nTzhVGrONPF1Kagg8oj9SOrjQgIJ7IbjK/QLQEWwNMz3Ywnhmc8ogrG2UuzJLhG3e\n/dLQwmpSnAXCGFPir6ZEz+mdUYHW3g3sYg38U6yetU+RaZ9DWsqVs74w5jS53vG0\nCy/IlVqL4M1wrUVorQyXOux4CI58O9ArbZ/xUEvVloKfD8CzqQdmO9erqyrrDhkL\n04CXKrboQ8djWpNk5MWWuQ==\n-----END ENCRYPTED PRIVATE KEY-----\n",
#     passphrase: "320c004d1e36338160c91daf78695309",
#   )

#   box_service.fetch_access_token

#   first_hearing = true

#   file_info[:hearings].each do |hearing|
#     begin
#       transcription_package = find_transcription_package(hearing)
#       unless transcription_package
#         error_details = {
#           error: {
#             type: "transcription_package",
#             message: "Transcription package not found for hearing ID: #{hearing[:hearing_id]}"
#           },
#           provider: "Box"
#         }
#         send_transcription_issues_email(error_details) unless email_sent?(:transcription_package)
#         mark_email_sent(:transcription_package)
#         next
#       end
#       local_file_path = transcription_package.aws_link_zip
#       contractor_name = file_info[:contractor_name]
#       child_folder_id = box_service.get_child_folder_id(box_folder_id, contractor_name)
#       unless child_folder_id
#         error_details = {
#           error: {
#             type: "child_folder_id",
#             message: "Child folder ID not found for contractor name: #{contractor_name}"
#           },
#           provider: "Box"
#         }
#         send_transcription_issues_email(error_details) unless email_sent?(:child_folder_id)
#         mark_email_sent(:child_folder_id)
#         break
#       end

#       # Download file from S3
#       # local_file_path = download_file_from_s3(file_path)

#       if first_hearing
#         upsert_to_box(box_service, local_file_path, child_folder_id, transcription_package, file_info, hearing)
#         first_hearing = false
#       else
#         create_to_box(box_service, local_file_path, child_folder_id, transcription_package, file_info, hearing)
#       end
#     rescue StandardError => error
#       log_error(error, extra: { transcription_package_id: transcription_package&.id })
#       error_details = { error: { type: "upload", message: error.message }, provider: "Box" }
#       send_transcription_issues_email(error_details) unless email_sent?(:upload)
#       mark_email_sent(:upload)
#       next
#     end
#   end
# end

# private

# def upsert_to_box(box_service, local_file_path, child_folder_id, transcription_package, file_info, hearing)
#   ActiveRecord::Base.transaction do
#     box_service.public_upload_file(local_file_path, child_folder_id)
#     Rails.logger.info("File successfully uploaded to Box folder ID: #{child_folder_id}")
#     transcription_package.update!(
#       date_upload_box: Time.current,
#       status: "Successful Upload (BOX)",
#       task_number: file_info[:work_order_name],
#       expected_return_date: file_info[:return_date],
#       updated_by_id: RequestStore[:current_user].id
#     )
#     transcription = Transcription.find_or_initialize_by(task_number: file_info[:work_order_name])
#     transcription.update!(
#       expected_return_date: file_info[:return_date],
#       hearing_id: hearing[:hearing_id],
#       sent_to_transcriber_date: Time.current,
#       transcriber: file_info[:contractor_name],
#       transcription_contractor_id: transcription_package.contractor_id,
#       updated_by_id: RequestStore[:current_user].id
#     )
#   end
# end

# def create_to_box(box_service, local_file_path, child_folder_id, transcription_package, file_info, hearing)
#   ActiveRecord::Base.transaction do
#     box_service.public_upload_file(local_file_path, child_folder_id)
#     Rails.logger.info("File successfully uploaded to Box folder ID: #{child_folder_id}")
#     transcription_package.update!(
#       date_upload_box: Time.current,
#       status: "Successful Upload (BOX)",
#       task_number: file_info[:work_order_name],
#       expected_return_date: file_info[:return_date],
#       updated_by_id: RequestStore[:current_user].id
#     )
#     transcription = Transcription.create!(
#       task_number: file_info[:work_order_name],
#       expected_return_date: file_info[:return_date],
#       hearing_id: hearing[:hearing_id],
#       sent_to_transcriber_date: Time.current,
#       transcriber: file_info[:contractor_name],
#       transcription_contractor_id: transcription_package.contractor_id,
#       updated_by_id: RequestStore[:current_user].id
#     )
#   end

