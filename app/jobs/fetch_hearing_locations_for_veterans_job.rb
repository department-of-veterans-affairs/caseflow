class FetchHearingLocationsForVeteranJob < ApplicationJob
  queue_as :low_priority
  application_attr :hearing_schedule

  def veteran_file_number_from_bfcorlid(bfcorlid)
    numeric = bfcorlid.gsub(/[^0-9]/, "")

    # ensure 8 digits if "C"-type id
    if bfcorlid.ends_with?("C")
      numeric.rjust(8, "0")
    else
      numeric
    end
  end

  def perform
    file_numbers = VACOLS::Case.where(bfcurloc: 57).pluck(:bfcorlid).map do |bfcorlid|
      veteran_file_number_from_bfcorlid(bfcorlid)
    end

    existing_veterans = Veteran.where(file_number: file_numbers).pluck(:file_number)
    missing_veterans = file_numbers - existing_veterans


    missing_veterans.each do |file_number|
      Veteran.find_or_create_by_file_number(file_number)
    end

    veterans = Veteran.where(file_number: file_numbers).
      includes(:hearing_locations).
      where("hearing_location.updated_at < ?", 1.month.ago).
      limit(500)


    veterans.each do |veteran|
      lat, long = ExternalApi::VADotGovService.geocode(
        address_line_1: veteran.address_line1,
        address_line2: veteran.address_line2,
        address_line3: veteran.address_line3,
        city: veteran.city,
        state: veteran.state,
        country: veteran.country,
        zip_code: veteran.zip_code
      )

      ro = "RO97"

      ids = RegionalOffice::Cities[ro][:alternate_locations] << RegionalOffice::Cities[ro][:facility_locator_id] # to be defined

      ExternalApi::VADotGovService(lat, long, ids).each do |alternate_hearing_location|
        AvailableHearingLocation.create(veteran_file_number: veteran.file_number, **alternate_hearing_location)
      end
    end
  end
end
