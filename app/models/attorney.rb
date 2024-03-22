# frozen_string_literal: true

class Attorney
  class << self
    def list_all
      Rails.cache.fetch("#{Rails.env}_list_of_attorneys_from_vacols") do
        AttorneyRepository.find_all_attorneys
      end
    end

    def list_all_hashes
      Rails.cache.fetch("#{Rails.env}_hashes_of_attorneys_from_vacols") do
        list_all.map do |attorney|
          {
            label: attorney.full_name,
            value: attorney.id
          }
        end
      end
    end
  end
end
