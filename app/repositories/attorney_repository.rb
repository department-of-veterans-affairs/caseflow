# frozen_string_literal: true

class AttorneyRepository
  include VACOLS::Staff

  class << self
    # Includes acting judges, who are normally attorneys
    def find_all_attorneys
      User.batch_find_by_css_id_or_create_with_default_station_id(find_all_having_attorney_ids_excluding_judges)
    end

    # Returns CSS_IDs of those with attorney_ids, including pure attorneys, pure judges, and acting judges
    def find_all_having_attorney_ids
      css_ids_from_records(active.having_attorney_id)
    end

    private

    # Returns CSS_IDs of pure attorneys and acting judges (who are normally attorneys)
    def find_all_having_attorney_ids_excluding_judges
      css_ids_from_records(attorney)
    end
  end
end
