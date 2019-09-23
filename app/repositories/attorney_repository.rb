# frozen_string_literal: true

class AttorneyRepository
  def self.find_all_attorneys
    css_ids = VACOLS::Staff.where(sactive: "A").where.not(sattyid: nil).where.not(sdomainid: nil)
      .pluck("UPPER(sdomainid)")

    # Create users in caseflow table
    new_user_css_ids = css_ids - User.where(css_id: css_ids).pluck(:css_id)
    User.create(new_user_css_ids.map { |css_id| { css_id: css_id, station_id: User::BOARD_STATION_ID } })

    User.where(css_id: css_ids)
  end
end
