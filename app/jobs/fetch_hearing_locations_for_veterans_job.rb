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
      left_outer_joins(:available_hearing_locations).
      where("available_hearing_locations.updated_at < ? OR available_hearing_locations.id IS NULL", 1.month.ago).
      limit(500)


    veterans.each do |veteran|

        # address_line_1: veteran.address_line1,
        # address_line2: veteran.address_line2,
        # address_line3: veteran.address_line3,
      lat, long = VADotGovService.geocode(
        address: veteran.address_line1,
        city: veteran.city,
        state: veteran.state,
        country: veteran.country,
        zip_code: veteran.zip_code
      )

      ro = "RO97"

      ids = RegionalOffice::CITIES[ro][:alternate_locations] << RegionalOffice::CITIES[ro][:facility_locator_id] # to be defined

      VADotGovService.get_distance([lat, long], ids).each do |alternate_hearing_location|
        AvailableHearingLocation.create(
          veteran_file_number: veteran.file_number,
          distance: alternate_hearing_location[:distance],
          facility_id: alternate_hearing_location[:id],
          name: alternate_hearing_location[:name],
          address: alternate_hearing_location[:address][:address_1]
        )
      end
    end
  end
end
