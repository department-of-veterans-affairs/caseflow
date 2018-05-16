class Task < ApplicationRecord
  belongs_to :assigned_to, class_name: "User"
  belongs_to :assigned_by, class_name: "User"
  # TODO: add polymorphic association
  belongs_to :appeal, class_name: "LegacyAppeal"

  validates :assigned_to, :assigned_by, :appeal, :action_type, :status, presence: true

  before_create :set_assigned_at, :set_assigned_to

  # TODO: missing: Waiver of AOJ letter and Hearing clarification letter
  # TODO: move it to the constants file
  ACTION_TYPES = {
    co_located: {
      ihp: "IHP",
      poa_clarification: "POA clarification",
      extension: "Extension",
      missing_hearing_transcripts: "Missing hearing transcripts",
      unaccredited_rep: "Unaccredited rep",
      foia: "FOIA",
      retired_vlj: "Retired VLJ",
      arneson: "Arneson",
      new_rep_arguments: "New rep arguments",
      pending_scanning_vbms: "Pending scanning (VBMS)",
      substituation_determination: "Substituation determination",
      address_verification: "Address verification",
      schedule_hearing: "Schedule hearing",
      missing_records: "Missing records",
      other: "Other"
    }
  }.freeze

  enum status: {
    assigned: 0,
    in_progress: 1,
    on_hold: 2,
    completed: 3
  }

  def co_located?
    ACTION_TYPES[:co_located].keys? include? action_type
  end

  private

  def set_assigned_at
    self.assigned_at = created_at
  end

  def set_assigned_to
    if co_located?
      self.assigned_to = User.find_or_create_by(
        css_id: Constants::CoLocatedTeams::USERS[Rails.current_env].sample,
        station_id: User::BOARD_STATION_ID
      )
    end
  end
end
