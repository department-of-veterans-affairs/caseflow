# frozen_string_literal: true

# TO-DO: confirm open-uri
require "open-uri"

class DownloadTranscriptionFileJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  # TO-DO: confirm priority
  queue_with_priority :low_priority

  retry_on(StandardError, attempts: 10, wait: :exponentially_longer) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")
  end

  def perform(download_link:, file_name:)
    ensure_current_user_is_set
    @file_name = file_name
    @transcription_file = find_or_create_transcription_file

    begin
      download_to_tmp(download_link)
      @transcription_file.update!(
        file_status: Constants.TRANSCRIPTION_FILE_STATUSES.retrieval.success,
        date_receipt_webex: Time.zone.now
      )
    ensure
      byebug
      clean_up_tmp_location
    end
  end

  private

  def download_to_tmp(download_link)
    begin
      URI.open(download_link) do |download|
        # @file_name = parse_file_name
        IO.copy_stream(download, tmp_location)
      end
    rescue OpenURI::HTTPError => error
      @transcription_file.update!(file_status: Constants.TRANSCRIPTION_FILE_STATUSES.retrieval.failure)
      raise error
    end
  end

  # def parse_file_name(download)
  #   download.meta["content-disposition"].match(/filename=(\"?)(.+)\1;/)[2]
  # end

  def tmp_location
    File.join(Rails.root, "tmp", "transcription_files", @file_name)
  end

  def clean_up_tmp_location
    return unless @file_name && File.exist?(tmp_location)

    File.delete(tmp_location)
  end

  def file_type
    @file_name.split(".")[-1]
  end

  def appeal
    @appeal = parse_appeal if appeal_attributes_present?
  end

  def appeal_attributes_present?
    @file_name.include?("Appeal")
  end

  def parse_appeal
    appeal_id = @file_name.split("_")[1]
    appeal_type = @file_name.split("_")[2]
    appeal_type.constantize.find(appeal_id)
  end

  def docket_number
    appeal&.docket_number || docket_number_from_hearing_day
  end

  # TO-DO: How to implement parsing docket number from hearing day?
  def docket_number_from_hearing_day
    byebug
  end

  def find_or_create_transcription_file
    TranscriptionFile.find_or_create_by(
      file_name: @file_name,
      docket_number: docket_number,
      appeal_id: appeal&.id,
      appeal_type: appeal&.class&.name
    ) do |file|
      file.file_type = file_type
      file.date_receipt_webex = Time.zone.today
      file.created_by_id = RequestStore[:current_user]
    end
  end
end
