# frozen_string_literal: true

class JudgeRepository
  # includes acting judges, who are normally attorneys
  def self.find_all_judges
    css_ids = judge_records.where.not(sdomainid: nil).pluck("UPPER(sdomainid)")

    User.batch_find_by_css_id_or_create_with_default_station_id(css_ids)
  end

  def self.find_all_judges_with_name_and_id
    # Our user model only contains a full name field, but for certain applications
    # (like the IDT), we need the separate name fields from VACOLS.
    judge_records.map do |record|
      { first_name: record.snamef,
        middle_name: record.snamemi,
        last_name: record.snamel,
        is_acting_judge: record.svlj == "A",
        vacols_attorney_id: record.sattyid }
    end
  end

  # includes acting judges
  def self.judge_records
    VACOLS::Staff.where(svlj: %w[J A], sactive: "A")
  end

  # :nocov:
  # excludes acting judges
  def self.judges
    VACOLS::Staff.where(svlj: "J", sactive: "A")
  end

  def self.acting_judges
    VACOLS::Staff.where(svlj: "A", sactive: "A")
  end
  # :nocov:
end
