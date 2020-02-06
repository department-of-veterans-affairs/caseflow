# frozen_string_literal: true

class AttorneyRepository

  # this includes judges for some reason
  def self.find_all_attorneys
    css_ids = VACOLS::Staff.where(sactive: "A").where.not(sattyid: nil).where.not(sdomainid: nil)
      .pluck("UPPER(sdomainid)")

    User.batch_find_by_css_id_or_create_with_default_station_id(css_ids)
  end

  def self.find_all_attorneys_without_judges
    # Optimize these into a single query once we agree this is what we want
    attys_and_judges = VACOLS::Staff.where(sactive: "A").where.not(sattyid: nil).where.not(sdomainid: nil).pluck("UPPER(sdomainid)")
    true_judges = VACOLS::Staff.where(svlj: "J", sactive: "A").where.not(sdomainid: nil).pluck("UPPER(sdomainid)")
    attys_and_acting_judges = attys_and_judges - true_judges

    User.batch_find_by_css_id_or_create_with_default_station_id(attys_and_acting_judges)
  end
end
