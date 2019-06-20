# frozen_string_literal: true

class VeteranFinder
  class << self
    def find_all(*file_numbers_or_ssns)
      file_numbers_or_ssns.flat_map(&VeteranFinder.method(:find_by_file_number_or_ssn))
    end

    def find_or_create_all(*file_numbers_or_ssns)
      file_numbers_or_ssns.flat_map(&VeteranFinder.method(:find_or_create_by_file_number_or_ssn))
    end

    private

    def find_or_create_by_file_number_or_ssn(file_number_or_ssn)
      veteran = Veteran.find_or_create_by_file_number_or_ssn(file_number_or_ssn)
      Veteran.where(participant_id: veteran.participant_id)
    end

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
        veteran_ssn_match = Veteran.find_by(file_number: veteran_file_number_match.ssn) if veteran_file_number_match
      end

      participant_ids = [veteran_file_number_match, veteran_ssn_match].compact.uniq.map(&:participant_id)

      Veteran.where(participant_id: participant_ids)
    end
  end
end
