# frozen_string_literal: true

class Attorney
  class << self
    def list_all
      Rails.cache.fetch("#{Rails.env}_list_of_attorneys_from_vacols") do
        AttorneyRepository.find_all_having_attorney_ids
      end
    end

    def list_all_excluding_judges
      Rails.cache.fetch("#{Rails.env}_list_of_attorneys_excluding_judges_from_vacols") do
        AttorneyRepository.find_all_having_attorney_ids_excluding_judges
      end
    end
  end
end
