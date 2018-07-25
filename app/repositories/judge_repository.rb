class JudgeRepository
  # :nocov:
  def self.find_all_judges
    records = VACOLS::Staff.where(svlj: %w[J A], sactive: "A")
    records.select(&:sdomainid).map do |record|
      User.find_or_create_by(css_id: record.sdomainid, station_id: User::BOARD_STATION_ID)
    end
  end

  def self.find_all_hearing_judges
    VACOLS::Staff.where("substr(stitle, 1, 1) = 'D') AND (svlj in ('A', 'J')")
  end

  # :nocov:
end
