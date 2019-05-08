# frozen_string_literal: true

class AttorneyRepository
  def self.find_all_attorneys
    records = VACOLS::Staff.where(sactive: "A").where.not(sattyid: nil)
    records.select(&:sdomainid).map do |record|
      User.find_by_css_id_or_create_with_default_station_id(record.sdomainid)
    end
  end
end
