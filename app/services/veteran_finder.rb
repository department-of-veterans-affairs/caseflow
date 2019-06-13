# frozen_string_literal: true

class VeteranFinder
  class << self
    def find_all(*file_numbers_or_ssns)
      file_numbers_or_ssns.flat_map(&VeteranFinder.method(:find_by_file_number_or_ssn))
    end

    private

    def find_by_file_number_or_ssn(file_number_or_ssn)
      if file_number_or_ssn.length == 9
        # The input is an SSN.
        ssn = file_number_or_ssn

        # There could be a veteran record where the file number is the SSN. There
        # could also be a BGS record with the veteran's SSN that maps back to a
        # different file number.
        veteran_file_number_match = Veteran.find_by(file_number: ssn)

        veteran_ssn_match = Veteran.find_by_ssn(ssn)
      else
        # The input is not an SSN. The value should be a claim number.
        file_number = file_number_or_ssn

        # If a veteran exists for the given claim number, there might be
        # another record where the file number is the veteran's SSN.
        veteran_file_number_match = Veteran.find_by(file_number: file_number)

        veteran_ssn_match = Veteran.find_by(file_number: veteran_by_file_number.ssn) if veteran_by_file_number
      end

      [veteran_file_number_match, veteran_ssn_match].compact.uniq
    end
  end
end
