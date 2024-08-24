# frozen_string_literal: true

class Hearings::MonitorBoxJob < ApplicationJob
  def perform
    check_box_dot_com_for_new_files
  end

  private

  BOX_PARENT_FOLDER_ID = Rails.env.production? ? ENV["BOX_PARENT_FOLDER_ID"] : "255974435715"

  def check_box_dot_com_for_new_files
    files = net_new_files

    files_with_permitted_keys(files)
  end

  def files_with_permitted_keys(files)
    permitted_keys = [:name, :id, :created_at]
    files.map { |hash| hash.slice!(*permitted_keys) }
    files
  end

  def net_new_files
    all_files_from_box_subfolders.find_all do |file|
      Time.parse(file[:created_at]).utc > 1.hour.ago.utc if file[:created_at]
    end
  end

  def all_files_from_box_subfolders
    folder_ids.map do |id|
      box_service.public_folder_details(id, "file")
    end.flatten
  end

  def folder_ids
    folders = box_service&.public_folder_details(BOX_PARENT_FOLDER_ID)
    folders.map { |folder| folder[:id] if folder[:name].downcase.include?("return") }.compact
  end

  def box_service
    case Rails.env
    when "production"
      @box_service ||= ExternalApi::VaBoxService.new(
        client_secret: ENV["BOX_CLIENT_SECRET"],
        client_id: ENV["BOX_CLIENT_ID"],
        enterprise_id: ENV["BOX_ENTERPRISE_ID"],
        private_key: ENV["BOX_PRIVATE_KEY"],
        passphrase: ENV["BOX_PASSPHRASE"]
      )

      @box_service.fetch_access_token

      @box_service
    else
      @box_service ||= ::Fakes::VaBoxService.new
    end
  end
end
