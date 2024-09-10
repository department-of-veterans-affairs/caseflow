# frozen_string_literal: true

class Hearings::MonitorBoxJob < ApplicationJob
  queue_as :low_priority

  attr_reader :box_service

  def initialize
    @box_service = ExternalApi::VaBoxService.new
  end

  def perform
    poll_box_dot_com_for_new_files
  rescue StandardError => error
    log_error(error)
    raise error
  end

  private

  def box_parent_folder_id
    ENV["BOX_PARENT_FOLDER_ID"]
  end

  def poll_box_dot_com_for_new_files
    files = net_new_files

    files_with_permitted_keys(files)
  end

  def files_with_permitted_keys(files)
    permitted_keys = [:name, :id, :created_at, :modified_at]
    files.map { |hash| hash.slice!(*permitted_keys) }
    files
  end

  def net_new_files
    cursor = most_recent_returned_file_time || 1.hour.ago.utc

    files = all_files_from_box_subfolders&.find_all do |file|
      Time.parse(file[:created_at]).utc > cursor
    end

    find_webex_formatted_files(files)
  end

  def most_recent_returned_file_time
    ::TranscriptionFile.maximum(:date_returned_box)
  end

  def find_webex_formatted_files(files)
    files.find_all do |file|
      file[:name].match?(webex_file_naming_convention)
    end
  end

  def webex_file_naming_convention
    # Returns a regular expression to find files using our naming convention transcription files from Webex hearings.
    # This is important since the Box.com folders will also contain transcription files from Pexip hearings
    # that we are not interested in for this workflow.
    #
    #   - For transcription files, "<docket number>_<hearing id OR appellant name>_<hearing type>.<file extension>"
    #     - ex. "123456-7_XXXXX_Hearing.XXX"
    #     - ex. "1234567_XXXXX_LegacyHearing.XXX"
    #   - For work orders, "<BVA>-<Four digit year>-<Task number>.xls"
    #     - ex. "BVA-2024-0001.xls"
    /(^[^_a-z]+_[^_]+_((Hearing)|(LegacyHearing))+.\w+\z)|(BVA-\d+-\d+.xls)/
  end

  def all_files_from_box_subfolders
    folder_ids.map do |id|
      box_service.get_folder_items(
        folder_id: id,
        item_type: "file",
        query_string: "sort=date&direction=desc&fields=name,created_at,modified_at"
      )
    end.flatten
  end

  def folder_ids
    folders = box_service&.get_folder_items(folder_id: ENV["BOX_PARENT_FOLDER_ID"])
    folders.map { |folder| folder[:id] if folder[:name].downcase.include?("return") }.compact
  end
end
