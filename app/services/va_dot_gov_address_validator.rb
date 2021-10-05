# frozen_string_literal: true

## Validates an appellant's address, and finds the closest regional office (RO) and
# available hearing locations (AHLs) based on their address.
#
# Note: distance to closest RO and AHLs is driving distance.
#
# See `ExternalApi::VADotGovService` for documentation of the external APIs that
# support this class.

class VaDotGovAddressValidator
  include VaDotGovAddressValidator::Validations

  attr_reader :appeal
  delegate :address, to: :appeal

  # The logic for these statuses is determined in `VaDotGovAddressValidator::ErrorHandler`.
  #
  # The mixin `VaDotGovAddressValidator::Validations` glues the `VaDotGovAddressValidator`
  # and `VaDotGovAddressValidator::ErrorHandler`.
  STATUSES = {
    # Successfully geomatched.
    matched_available_hearing_locations: :matched_available_hearing_locations,

    # Address was in the Philippines, and assigned to RO58.
    philippines_exception: :defaulted_to_philippines_RO58,

    # Foreign addresses need to be handled by an admin.
    created_foreign_veteran_admin_action: :created_foreign_veteran_admin_action,

    # An admin needs to manually handle addresses that can't be verified.
    created_verify_address_admin_action: :created_verify_address_admin_action
  }.freeze

  def initialize(appeal:)
    @appeal = appeal
  end

  # Geomatches an appeal to a regional office and discovers nearby locations where
  # the hearing can be held.
  #
  # @return            [Hash]
  #   A hash with the geocoding status (see `VaDotGovAddressValidator#STATUSES`)
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
      return unless closest_ro_response.success?

      # Note: In `ro_facility_ids_to_geomatch`, the San Antonio facility ID is passed
      # as a valid RO for any veteran living in Texas.
      return "RO62" if closest_regional_office_facility_id_is_san_antonio?

      RegionalOffice
        .cities
        .detect do |ro|
          ro.facility_id == closest_ro_facility_id
        end
        .key
    end
  end

  def available_hearing_locations
    @available_hearing_locations ||= available_hearing_locations_response.data
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

  # Gets a list of RO facility ids to geomatch with.
  #
  # @return            [Array<String>]
  #   Array of all RO facility ids for Travel board appeals or RO facility IDs by state for all other appeal types
  def ro_facility_ids_to_geomatch
    # only match to Central office if veteran requested central office
    return ["vba_372"] if appeal_is_legacy_and_veteran_requested_central_office?

    # Return the list of RO facility IDs
    if appeal.current_hearing_request_type == :travel_board
      Rails.logger.info("Travel Board Appeal Geomatching | Appeal ID: #{appeal.class.name}#{appeal.id}")
      # Exclude the DC regional office, unlikely that would be a "Travel" hearing
      # and the facility_id is invalid according to the VA.gov API
      return RegionalOffice.ro_facility_ids - ["vba_372"]
    end

    facility_ids = RegionalOffice.ro_facility_ids_for_state(state_code)

    # veterans whose closest AHL is San Antonio should have Houston as the RO
    # even though Waco may be closer. This is a RO/AHL policy quirk.
    # see https://github.com/department-of-veterans-affairs/caseflow/issues/9858
    #
    # Note: In the logic to determine the closest RO, there is logic that maps this
    # facility ID to the Houston RO.
    facility_ids << "vha_671BY" if veteran_lives_in_texas? # include San Antonio facility id

    facility_ids
  end

  private

  def update_closest_regional_office
    appeal.update(closest_regional_office: closest_regional_office_with_exceptions)
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

  def available_hearing_locations_response
    @available_hearing_locations_response ||= VADotGovService.get_distance(
      ids: RegionalOffice.facility_ids_for_ro(closest_regional_office_with_exceptions),
      lat: valid_address[:lat],
      long: valid_address[:long]
    )
  end

  def closest_ro_response
    @closest_ro_response ||= VADotGovService.get_distance(
      ids: ro_facility_ids_to_geomatch,
      lat: valid_address[:lat],
      long: valid_address[:long]
    )
  end

  def closest_ro_facility_id
    closest_ro_response.data.first&.dig(:facility_id)
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
