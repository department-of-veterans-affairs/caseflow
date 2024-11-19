# frozen_string_literal: true

class Hearings::VaBoxUploadJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet
  include Shoryuken::Worker
  include Hearings::SendTranscriptionIssuesEmail

  queue_as :low_priority
  shoryuken_options retry_intervals: [3.seconds, 30.seconds, 5.minutes, 30.minutes, 2.hours, 5.hours]
  before_perform { ensure_current_user_is_set }

  S3_BUCKET = "vaec-appeals-caseflow"

  VACOLS_CONTRACTORS = {
    "Genesis Government Solutions, Inc." => "G",
    "Jamison Professional Services" => "J",
    "Vet Reporting" => "V"
  }.freeze

  class BoxUploadError < StandardError; end

  retry_on StandardError, wait: :exponentially_longer do |job, exception|
    job.cleanup_tmp_file
    error_details = { error: { type: "upload", message: exception.message }, provider: "Box" }
    job.send_transcription_issues_email(error_details) unless job.email_sent?(:upload)
    job.mark_email_sent(:upload)
    fail BoxUploadError
  end

  def initialize(transcription_package)
    @transcription_package = transcription_package
    @master_zip_file_path = ""
    @email_sent_flags = { transcription_package: false, child_folder_id: false, upload: false }
  end

  def perform
    begin
      upload_master_zip_to_box
      update_database_records
    rescue StandardError => error
      log_error(error, extra: { transcription_package_id: @transcription_package&.id })
      error_details = { error: { type: "upload", message: error.message }, provider: "Box" }
      send_transcription_issues_email(error_details) unless email_sent?(:upload)
      mark_email_sent(:upload)
    end
  end

  private

  def box_service
    @box_service ||= ExternalApi::VaBoxService.new
  end

  def upload_master_zip_to_box
    download_file_from_s3(@transcription_package.aws_link_zip)
    box_service.upload_file(@master_zip_file_path, child_folder_id)
    Rails.logger.info("File successfully uploaded to Box folder ID: #{child_folder_id}")
  end

  def child_folder_id
    box_service.get_child_folder_id(
      ENV["BOX_PARENT_FOLDER_ID"],
      contractor_name
    )
  end

  def contractor_name
    @transcription_package.contractor&.name
  end

  def download_file_from_s3(s3_path)
    @master_zip_file_path = Rails.root.join("tmp", "transcription_files", File.basename(s3_path))
    Caseflow::S3Service.fetch_file(s3_path, @master_zip_file_path)
    Rails.logger.info("File successfully downloaded from S3: #{@master_zip_file_path}")
    @master_zip_file_path
  end

  def update_database_records
    ActiveRecord::Base.transaction do
      update_transcription_package
      update_transcriptions
      update_transcription_files
      update_vacols_hearsched
    end
  end

  def update_transcription_package
    @transcription_package.update!(
      date_upload_box: Time.current,
      status: "Successful Upload (BOX)",
      updated_by_id: RequestStore[:current_user].id
    )
  end

  def update_transcriptions
    @transcription_package.transcriptions.each do |transcription|
      transcription.update!(
        transcription_contractor: @transcription_package.contractor,
        updated_by_id: RequestStore[:current_user].id,
        # not 100% sure about this status
        transcription_status: "Successful Upload (BOX)",
        sent_to_transcriber_date: Time.current.to_date
      )
    end
  end

  def update_transcription_files
    @transcription_package.transcriptions&.each do |transcription|
      transcription.transcription_files&.update_all!(
        date_upload_box: Time.current,
        updated_by_id: RequestStore[:current_user].id,
        # not 100% sure about this status
        file_status: "sent"
      )
    end
  end

  def update_vacols_hearsched
    return if @transcription_package.legacy_hearings.blank?

    @transcription_package.legacy_hearings.each do |hearing|
      vacols_record = VACOLS::CaseHearing.find_by(hearing_pkseq: hearing.vacols_id)
      vacols_record.update!(
        taskno: truncate_task_number_for_vacols(@transcription_package.task_number),
        contapes: VACOLS_CONTRACTORS[@transcription_package.contractor&.name],
        consent: Time.current.to_date,
        conret: @transcription_package.expected_return_date
      )
    end
  end

  def truncate_task_number_for_vacols(task_number)
    # convert "BVA-YYYY-0001" to "YY-0001"
    task_number[6..-1]
  end

  def cleanup_tmp_file
    return if @master_zip_file_path.blank?

    File.exist?(@master_zip_file_path) ? File.delete(@master_zip_file_path) : return
    Rails.logger.info("Cleaned up the following file from tmp: #{@master_zip_file_path}")
  end

  def email_sent?(type)
    @email_sent_flags[type]
  end

  def mark_email_sent(type)
    @email_sent_flags[type] = true
  end
end
