class CoLocatedAdminAction < Task
  # TODO: move it to the constants file
  TITLES = {
    ihp: "IHP",
    poa_clarification: "POA clarification",
    hearing_clarification: "Hearing clarification",
    aoj: "AOJ",
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
  }.freeze

  after_initialize :set_assigned_to
  validates :title, inclusion: { in: TITLES.keys.map(&:to_s) }
  validate :assigned_by_role_is_valid

  private

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be an attorney") if assigned_by && assigned_by.vacols_role != "Attorney"
  end

  def set_assigned_to
    self.assigned_to = User.find_or_create_by(
      css_id: Constants::CoLocatedTeams::USERS[Rails.current_env].sample,
      station_id: User::BOARD_STATION_ID
    )
  end
end
