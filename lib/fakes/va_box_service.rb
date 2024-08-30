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
        { name: "123456-1234-5678-AMA.zip",
          id: "1619614326659",
          created_at: recent_date,
          modified_at: "2024-08-29T16:26:08.402-05:00",
          type: "file",
          etag: "0" },
        { name: "987654-1234-5678-AMA.zip",
          id: "1619969073264",
          created_at: recent_date,
          modified_at: "2024-08-29T16:26:08.402-05:00",
          type: "file",
          etag: "0" },
        { name: "654321-1234-1234-AMA.zip",
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
        { name: "BVA-1234-5678-AMA.zip",
          id: "1628675803016",
          created_at: recent_date,
          modified_at: "2024-08-29T16:26:08.402-05:00",
          type: "file",
          etag: "0" }
      ]
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  def recent_date
    JSON.parse(rand(59.minutes.ago..Time.zone.now).to_json)
  end

  def not_recent_date
    JSON.parse(rand(2.days.ago..1.day.ago).to_json)
  end
end
