# frozen_string_literal: true

class AttorneyRepository
  class << self
    def find_all_attorneys
      User.batch_find_by_css_id_or_create_with_default_station_id(find_all_having_attorney_ids_excluding_judges)
    end

    # returns CSS_IDs of those with attorney_ids, including attorneys and judges
    def find_all_having_attorney_ids
      VACOLS::Staff.where(sactive: "A").where.not(sdomainid: nil).where.not(sattyid: nil)
        .pluck("sdomainid").map(&:upcase)
    end

    private

    # returns CSS_IDs of attorneys and acting judges (who are normally attorneys)
    def find_all_having_attorney_ids_excluding_judges
      VACOLS::Staff.where(sactive: "A").where.not(sdomainid: nil).where.not(sattyid: nil)
        .where(svlj: [nil, "A"]).pluck("sdomainid").map(&:upcase)
    end
  end
end
