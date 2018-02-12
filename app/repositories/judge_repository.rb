class JudgeRepository
  # :nocov:
  def self.find_all_judges
    records = VACOLS::Staff.where(svlj: "J", sactive: "A")
    records.map { |record| Judge.create_from_vacols(record) if record.sdomainid }
  end
  # :nocov:
end
