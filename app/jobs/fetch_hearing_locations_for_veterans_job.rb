class FetchHearingLocationsForVeteransJob < ApplicationJob
  queue_as :low_priority
  application_attr :hearing_schedule

  def veterans
    @veterans ||= Veteran.where(file_number: file_numbers)
      .left_outer_joins(:available_hearing_locations)
      .where("available_hearing_locations.updated_at < ? OR available_hearing_locations.id IS NULL", 1.month.ago)
      .limit(500)
  end

  def file_numbers
    @file_numbers ||= VACOLS::Case.where(bfcurloc: 57).pluck(:bfcorlid).map do |bfcorlid|
      LegacyAppeal.veteran_file_number_from_bfcorlid(bfcorlid)
    end
  end

  def missing_veteran_file_numbers
    existing_veteran_file_numbers = Veteran.where(file_number: file_numbers).pluck(:file_number)
    file_numbers - existing_veteran_file_numbers
  end

  def create_missing_veterans
    missing_veteran_file_numbers.each do |file_number|
      Veteran.find_or_create_by_file_number(file_number)
    end
  end

  def create_available_locations_for_veteran(veteran, lat, long, ids)
    VADotGovService.get_distance(lat: lat, long: long, ids: ids).each do |alternate_hearing_location|
      AvailableHearingLocations.create(
        veteran_file_number: veteran.file_number,
        distance: alternate_hearing_location[:distance],
        facility_id: alternate_hearing_location[:id],
        name: alternate_hearing_location[:name],
        address: alternate_hearing_location[:address]["address_1"]
      )
    end
  end

  def perform
    create_missing_veterans

    veterans.each do |veteran|
      lat, long = VADotGovService.geocode(
        address_line1: veteran.address_line1,
        address_line2: veteran.address_line2,
        address_line3: veteran.address_line3,
        city: veteran.city,
        state: veteran.state,
        country: veteran.country,
        zip_code: veteran.zip_code
      )

      facility_ids = facility_ids_for_veteran veteran

      create_available_locations_for_veteran veteran, lat, long, facility_ids
    end
  end

  private

  def ros_hash
    bfcorlids = veterans.pluck(:file_number).map do |file_number|
      LegacyAppeal.convert_file_number_to_vacols(file_number)
    end

    VACOLS::Case.where(bfcorlid: bfcorlids).pluck(:bfcorlid, :bfregoff).to_h
  end

  def facility_ids_for_veteran(veteran)
    file_number = LegacyAppeal.convert_file_number_to_vacols(veteran.file_number)
    ro = ros_hash[file_number]

    RegionalOffice::CITIES[ro][:alternate_locations] || [] << RegionalOffice::CITIES[ro][:facility_locator_id]
  end
end
