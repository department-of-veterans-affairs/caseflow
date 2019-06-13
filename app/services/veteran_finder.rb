# frozen_string_literal: true

class VeteranFinder
  class << self
    def find_all(*file_numbers_or_ssns)
      file_numbers_or_ssns.flat_map do |one_file_number_or_ssn|
        # Multiple possibilities:
        #
        #   1. The input is an SSN or File Number that maps directly to the `file_number`
        #      field for a vet.
        #   2. The input is an SSN that requires a BGS lookup for the File Number.
        #   3. Combination of both.
        veteran_file_number_or_ssn = Veteran.find_by(file_number: one_file_number_or_ssn)
        veteran_bgs_lookup = if one_file_number_or_ssn.length == 9
                               Veteran.find_by_ssn(one_file_number_or_ssn)
                             end

        [veteran_file_number_or_ssn, veteran_bgs_lookup].select { |vet| !vet.nil? }.uniq(&:id)
      end
    end
  end
end
