# frozen_string_literal: true

class Fakes::VaBoxService
  # rubocop:disable Metrics/MethodLength

  # Changing values in this file will affect spec/jobs/hearings/monitor_box_job_spec.rb

  def get_folder_items(folder_id:, item_type: "folder", query_string: nil)
    case item_type
    when "folder"
      [
        { type: "folder", id: "262846883396", sequence_id: "0", etag: "0", name: "Genesis Pickup" },
        { type: "folder", id: "262846453574", sequence_id: "0", etag: "0", name: "Genesis Return" }
      ]
    when "file"
      [
        { name: "123456-1_5678_Hearing.doc",
          id: "1619614326659",
          created_at: recent_date,
          modified_at: "2024-08-29T16:26:08.402-05:00",
          type: "file",
          etag: "0" },
        { name: "BVA-2024-0001.xls",
          id: "1619969073264",
          created_at: recent_date,
          modified_at: "2024-08-29T16:26:08.402-05:00",
          type: "file",
          etag: "0" },
        { name: "654321-1_1234_Hearing.doc",
          id: "1620513326164",
          created_at: not_recent_date,
          modified_at: "2024-08-29T16:26:08.402-05:00",
          type: "file",
          etag: "0" },
        { name: "NOT_THE_CORRECT_NAMING_CONVENTION.zip",
          id: "1628631707374",
          created_at: recent_date,
          modified_at: "2024-08-29T16:26:08.402-05:00",
          type: "file",
          etag: "0" },
        { name: "1234567_2342_LegacyHearing.pdf",
          id: "1628675803016",
          created_at: recent_date,
          modified_at: "2024-08-29T16:26:08.402-05:00",
          type: "file",
          etag: "0" }
      ]
    end
  end
  # rubocop:enable Metrics/MethodLength

  def download_file(id, tmp_folder)
    if id == "1111111111111"
      fail StandardError
    end

    file_extension = File.extname(tmp_folder).delete(".").to_s
    FileUtils.mkdir_p(File.dirname(tmp_folder)) unless Dir.exist?(file_extension)
    File.open(tmp_folder.to_s, "w") { |f| f.write "test" }
  end

  def upload_file(path, id)
    true
  end

  def fetch_access_token
    true
  end

  def get_child_folder_id(parent_folder_id, child_folder_name)
    ""
  end

  private

  def recent_date
    JSON.parse(rand(59.minutes.ago..Time.zone.now).to_json)
  end

  def not_recent_date
    JSON.parse(rand(2.days.ago..1.day.ago).to_json)
  end
end
