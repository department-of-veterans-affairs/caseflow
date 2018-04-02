class JudgeRepository
  # :nocov:
  def self.find_all_judges
    records = VACOLS::Staff.where(svlj: %w[J A], sactive: "A")
    records.select(&:sdomainid).map { |record| Judge.create_from_vacols(record) }
  end
  # :nocov:
end
