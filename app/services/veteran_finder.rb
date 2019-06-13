# frozen_string_literal: true

class VeteranFinder
  class << self
    def find_all(*file_numbers_or_ssns)
      file_numbers_or_ssns.flat_map(&VeteranFinder.method(:find_by_file_number_or_ssn))
    end

    private

    def find_by_file_number_or_ssn(file_number_or_ssn)
      # Multiple possibilities:
      #
      #   1. The input is an SSN or File Number that maps directly to the `file_number`
      #      field for a vet.
      #   2. The input is an SSN that requires a BGS lookup for the file number OR
      #      the input is not an SSN, and there might be a Veteran with the SSN as a
      #      file number.
      #   3. Combination of both.
      veteran_file_number_or_ssn = Veteran.find_by(file_number: file_number_or_ssn)
      veteran_bgs_lookup = if file_number_or_ssn.length == 9
                             Veteran.find_by_ssn(file_number_or_ssn)
                           elsif veteran_file_number_or_ssn
                             Veteran.find_by(file_number: veteran_file_number_or_ssn.ssn)
                           end

      [veteran_file_number_or_ssn, veteran_bgs_lookup].compact.uniq
    end
  end
end
