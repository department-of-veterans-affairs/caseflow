# frozen_string_literal: true

class AttorneyRepository
  class << self
    def find_all_attorneys
      find_all_having_attorney_ids_excluding_judges
    end

    # this includes judges
    def find_all_having_attorney_ids
      css_ids = VACOLS::Staff.where(sactive: "A").where.not(sattyid: nil).where.not(sdomainid: nil)
        .pluck("UPPER(sdomainid)")

      User.batch_find_by_css_id_or_create_with_default_station_id(css_ids)
    end

    private

    # returns attorneys and acting judges (who are normally attorneys)
    def find_all_having_attorney_ids_excluding_judges
      attys_and_acting_judges = VACOLS::Staff.where(sactive: "A").where.not(sdomainid: nil)
        .where.not(sattyid: nil).where(svlj: [nil, "A"]).pluck("UPPER(sdomainid)")

      User.batch_find_by_css_id_or_create_with_default_station_id(attys_and_acting_judges)
    end
  end
end
