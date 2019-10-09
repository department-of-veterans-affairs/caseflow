# frozen_string_literal: true

class AttorneyRepository
  def self.find_all_attorneys
    css_ids = VACOLS::Staff.where(sactive: "A").where.not(sattyid: nil).where.not(sdomainid: nil)
      .pluck("UPPER(sdomainid)")

    User.batch_find_by_css_id_or_create_with_default_station_id(css_ids)
  end
end
