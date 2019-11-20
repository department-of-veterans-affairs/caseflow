# frozen_string_literal: true

class VeteranFinder
  class << self
    def find_or_create_all(*file_numbers_or_ssns)
      file_numbers_or_ssns.flat_map(&VeteranFinder.method(:find_or_create_by_file_number_or_ssn)).uniq
    end

    def find_best_match(file_number_or_ssn)
      if file_number_or_ssn.to_s.length == 9
        found_by_ssn = find_preferred_by_ssn(file_number_or_ssn)

        return found_by_ssn if found_by_ssn

        find_best_match_by_ssn(file_number_or_ssn)
      else
        find_best_match_by_file_number(file_number_or_ssn)
      end
    end

    private

    def find_best_match_by_ssn(ssn)
      vets = find_or_create_by_file_number_or_ssn(ssn)
      vets.select { |vet| vet[:ssn].present? }.find { |vet| vet.ssn.to_s == ssn.to_s } || vets.first
    end

    def find_best_match_by_file_number(file_number)
      vets = find_or_create_by_file_number_or_ssn(file_number)
      vets.find { |vet| vet.file_number.to_s == file_number.to_s } || vets.first
    end

    def find_preferred_by_ssn(ssn)
      Veteran.where(ssn: ssn).where.not(file_number: ssn).first || Veteran.find_by(ssn: ssn)
    end

    def find_or_create_by_file_number_or_ssn(file_number_or_ssn)
      veteran = Veteran.find_or_create_by_file_number_or_ssn(file_number_or_ssn)

      return [] unless veteran&.participant_id

      Veteran.where(participant_id: veteran.participant_id)
    end
  end
end
