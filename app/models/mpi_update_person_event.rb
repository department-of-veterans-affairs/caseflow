# frozen_string_literal: true

class MpiUpdatePersonEvent < CaseflowRecord
  belongs_to :api_key, optional: false

  validates :update_type, presence: true

  enum update_type: {
    started: "started",
    no_veteran: "no_veteran",
    multiple_veterans: "multiple_veterans",
    already_deceased: "already_deceased",
    already_deceased_time_changed: "already_deceased",
    missing_deceased_info: "missing_deceased_info",
    successful: "successful",
    error: "error"
  }
end
