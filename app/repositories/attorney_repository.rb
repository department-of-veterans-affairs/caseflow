# frozen_string_literal: true

class AttorneyRepository
  class << self
    # Includes acting judges, who are normally attorneys
    def find_all_attorneys
      User.batch_find_by_css_id_or_create_with_default_station_id(find_all_having_attorney_ids_excluding_judges)
    end

    private

    # Returns CSS_IDs of pure attorneys and acting judges (who are normally attorneys)
    def find_all_having_attorney_ids_excluding_judges
      VACOLS::Staff.css_ids_from_records_with_css_ids(VACOLS::Staff.attorney)
    end
  end
end
