# frozen_string_literal: true

class MpiUpdatePersonEvent < CaseflowRecord
  belongs_to :api_key, optional: false

  validates :update_type, presence: true

  enum update_type: {
    no_veteran: "NO_VETERAN",
    already_deceased: "ALREADY_DECEASED",
    missing_deceased_info: "MISSING_DECEASED_INFO",
    successful: "SUCCESSFUL",
    error: "ERROR"
  }
end
