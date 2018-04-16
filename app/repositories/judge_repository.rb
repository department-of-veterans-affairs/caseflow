class JudgeRepository
  # :nocov:
  def self.find_all_judges
    records = VACOLS::Staff.where(svlj: %w[J A], sactive: "A")
    records.select(&:sdomainid).map do |record|
      User.create_from_vacols(
        css_id: record.sdomainid,
        station_id: User::BOARD_STATION_ID,
        full_name: FullName.new(record.snamef, record.snamemi, record.snamel).formatted(:readable_full)
      )
    end
  end
  # :nocov:
end
