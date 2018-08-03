class JudgeRepository
  def self.find_all_judges
    judge_records.select(&:sdomainid).map do |record|
      User.find_or_create_by(css_id: record.sdomainid, station_id: User::BOARD_STATION_ID)
    end
  end

<<<<<<< HEAD
=======
  # :nocov:
>>>>>>> e7025f8e3c74004dc91351df96e8c5950f49a7ed
  def self.find_all_judges_with_name_and_id
    # Our user model only contains a full name field, but for certain applications
    # (like the IDT), we need the separate name fields from VACOLS.
    judge_records.map do |record|
      { first_name: record.snamef,
        middle_name: record.snamemi,
        last_name: record.snamel,
        vacols_attorney_id: record.sattyid }
    end
  end

  def self.judge_records
    VACOLS::Staff.where(svlj: %w[J A], sactive: "A")
  end
end
