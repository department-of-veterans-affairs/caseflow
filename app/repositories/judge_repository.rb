# frozen_string_literal: true

class JudgeRepository
  # Includes acting judges, who are normally attorneys
  def self.find_all_judges
    css_ids = VACOLS::Staff.css_ids_from_records(VACOLS::Staff.judge)

    User.batch_find_by_css_id_or_create_with_default_station_id(css_ids)
  end

  def self.find_all_judges_with_name_and_id
    # Our user model only contains a full name field, but for certain applications
    # (like the IDT), we need the separate name fields from VACOLS.
    VACOLS::Staff.judge.map do |record|
      { first_name: record.snamef,
        middle_name: record.snamemi,
        last_name: record.snamel,
        is_acting_judge: record.svlj == "A",
        vacols_attorney_id: record.sattyid }
    end
  end
end
