# frozen_string_literal: true

class VaDotGovAddressValidator
  include VaDotGovAddressValidator::Validations

  attr_reader :appeal
  delegate :address, to: :appeal

  STATUSES = {
    matched_available_hearing_locations: :matched_available_hearing_locations,
    philippines_exception: :defaulted_to_philippines_RO58,
    created_foreign_veteran_admin_action: :created_foreign_veteran_admin_action,
    created_verify_address_admin_action: :created_verify_address_admin_action
  }.freeze

  def initialize(appeal:)
    @appeal = appeal
  end

  def update_closest_ro_and_ahls
    return { status: error_status } if error_status.present?

    update_closest_regional_office
    destroy_existing_available_hearing_locations!
    create_available_hearing_locations

    { status: :matched_available_hearing_locations }
  end

  def valid_address
    @valid_address ||= if valid_address_response.success?
                         valid_address_response.data
                       else
                         validate_zip_code
                       end
  end

  def state_code
    map_country_code_to_state
  end

  def closest_regional_office
    @closest_regional_office ||= begin
      return unless closest_facility_response.success?

      VaDotGovAddressValidator::ClosestRegionalOfficeFinder.new(
        facilities: closest_facility_response.data,
        closest_facility_id: closest_facility_id
      ).call
    end
  end

  def available_hearing_locations
    @available_hearing_locations ||= begin
      ids = RegionalOffice.facility_ids_for_ro(closest_regional_office)
      closest_facility_response.data.select { |facility| ids.include?(facility[:facility_id]) }
    end
  end

  def assign_ro_and_update_ahls(new_ro)
    appeal.update(closest_regional_office: new_ro)

    assign_available_hearing_locations_for_ro(regional_office_id: new_ro)
  end

  def assign_available_hearing_locations_for_ro(regional_office_id:)
    destroy_existing_available_hearing_locations!

    facility_ids = RegionalOffice.facility_ids_for_ro(regional_office_id)

    VADotGovService.get_facility_data(ids: facility_ids).data.each do |facility|
      create_available_hearing_location(facility: facility)
    end
  end

  def get_distance_to_facilities(facility_ids:)
    return valid_address_response unless valid_address_response.success?

    VADotGovService.get_distance(lat: valid_address[:lat],
                                 long: valid_address[:long],
                                 ids: facility_ids)
  end

  def facility_ids_to_geomatch
    # only match to Central office if veteran requested central office
    return ["vba_372"] if appeal_is_legacy_and_veteran_requested_central_office?

    RegionalOffice.facility_ids
  end

  private

  def update_closest_regional_office
    appeal.update(closest_regional_office: closest_regional_office)
  end

  def destroy_existing_available_hearing_locations!
    AvailableHearingLocations.where(appeal: appeal).destroy_all
  end

  def create_available_hearing_locations
    available_hearing_locations.map do |facility|
      create_available_hearing_location(facility: facility)
    end
  end

  def create_available_hearing_location(facility:)
    AvailableHearingLocations.create(
      veteran_file_number: appeal.veteran_file_number || "",
      appeal: appeal,
      distance: facility[:distance],
      facility_id: facility[:facility_id],
      name: facility[:name],
      address: facility[:address],
      city: facility[:city],
      state: facility[:state],
      zip_code: facility[:zip_code],
      classification: facility[:classification],
      facility_type: facility[:facility_type]
    )
  end

  def valid_address_response
    @valid_address_response ||= VADotGovService.validate_address(address)
  end

  def closest_facility_response
    @closest_facility_response ||= VADotGovService.get_distance(
      ids: facility_ids_to_geomatch,
      lat: valid_address[:lat],
      long: valid_address[:long]
    )
  end

  def closest_facility_id
    closest_facility_response.data[0]&.dig(:facility_id)
  end

  def validate_zip_code
    if address.zip_code_not_validatable?
      nil
    else
      lat_lng = ZipCodeToLatLngMapper::MAPPING[address.zip[0..4]]

      return nil if lat_lng.nil?

      { lat: lat_lng[0], long: lat_lng[1], country_code: address.country, state_code: address.state }
    end
  end
end
