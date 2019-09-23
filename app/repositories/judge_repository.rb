# frozen_string_literal: true

class JudgeRepository
  def self.find_all_judges
    css_ids = judge_records.where.not(sdomainid: nil).pluck("UPPER(sdomainid)")

    # Create users in caseflow table
    new_user_css_ids = css_ids - User.where(css_id: css_ids).pluck(:css_id)
    User.create(new_user_css_ids.map { |css_id| { css_id: css_id, station_id: User::BOARD_STATION_ID } })

    User.where(css_id: css_ids)
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

  def self.judge_records
    VACOLS::Staff.where(svlj: %w[J A], sactive: "A")
  end
end
