# frozen_string_literal: true

class VeteranFinder
  class << self
    def find_or_create_all(*file_numbers_or_ssns)
      file_numbers_or_ssns.flat_map(&VeteranFinder.method(:find_or_create_by_file_number_or_ssn)).uniq
    end

    private

    def find_or_create_by_file_number_or_ssn(file_number_or_ssn)
      veteran = Veteran.find_or_create_by_file_number_or_ssn(file_number_or_ssn)

      return [] unless veteran && veteran.participant_id

      Veteran.where(participant_id: veteran.participant_id)
    end
  end
end
