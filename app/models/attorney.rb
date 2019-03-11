# frozen_string_literal: true

class Attorney
  class << self
    def list_all
      Rails.cache.fetch("#{Rails.env}_list_of_attorneys_from_vacols") do
        AttorneyRepository.find_all_attorneys
      end
    end
  end
end
