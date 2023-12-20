# frozen_string_literal: true

class FileNumberUpdateDetector
  attr_reader :veteran

  def initialize(veteran:)
    @veteran = veteran
  end

  # Find and return a new file number for the veteran, or nil if no update is detected.
  # This can also raise a BgsFileNumberMismatch if the proper file number could not be found.
  def new_file_number
    bgs_file_number = bgs.fetch_file_number_by_ssn(veteran.ssn)
    return if bgs_file_number == veteran.file_number

    if bgs_file_number.nil? && bgs.fetch_veteran_info(veteran.file_number)[:ssn] != veteran.ssn
      fail(Caseflow::Error::BgsFileNumberMismatch, veteran_id: veteran.id)
    end

    bgs_file_number
  end

  private

  def bgs
    @bgs ||= BGSService.new
  end
end
