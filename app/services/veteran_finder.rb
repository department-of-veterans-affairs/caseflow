class VeteranFinder
  def find(file_number_or_ssn)
    if file_number_or_ssn.to_s.length == 9
      find_by_filenumber(file_number_or_ssn) || find_by_ssn(file_number_or_ssn)
    else
      find_by_filenumber(file_number_or_ssn)
    end
  end

  private

  def find_by_ssn(ssn)
    file_number = bgs.fetch_file_number_by_ssn(ssn)
    return unless file_number
    find_by_filenumber(file_number)
  end

  def find_by_filenumber(file_number)
    veteran = Veteran.find_by(file_number: file_number)
    return veteran if veteran
    veteran = Veteran.new(file_number: file_number)
    return veteran if veteran.fetch_bgs_record
  end

  def bgs
    @bgs ||= BGSService.new
  end
end
