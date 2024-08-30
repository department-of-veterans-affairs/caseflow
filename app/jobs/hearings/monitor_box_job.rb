# frozen_string_literal: true

class Hearings::MonitorBoxJob < ApplicationJob
  queue_as :low_priority

  attr_reader :box_service

  def initialize
    @box_service = ExternalApi::VaBoxService.new
  end

  def perform
    poll_box_dot_com_for_new_files
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

    filter_non_webex_files(files)
  end

  def most_recent_returned_file_time
    # uncomment after date_return box_migration
    # ::TranscriptionFile.maximum(:date_return_box)
  end

  def filter_non_webex_files(files)
    files.find_all do |file|
      /\w{1,10}-\d{4}-\d{4}-AMA..{3,4}/.match?(file[:name])
    end
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
