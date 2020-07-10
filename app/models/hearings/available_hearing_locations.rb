# frozen_string_literal: true

class AvailableHearingLocations < CaseflowRecord
  include HasAppealUpdatedSince

  belongs_to :veteran, foreign_key: :file_number, primary_key: :veteran_file_number
  belongs_to :appeal, polymorphic: true

  def to_hash
    {
      name: name,
      address: address,
      city: city,
      state: state,
      distance: distance,
      facility_id: facility_id,
      facility_type: facility_type,
      classification: classification,
      zip_code: zip_code,
      formatted_facility_type: formatted_facility_type
    }
  end

  # this will eventually replace getFacilityType in AppealHearingLocations
  # in upcoming pagination work
  def formatted_facility_type
    case facility_type
    when "vet_center"
      "(Vet Center)"
    when "va_health_facility"
      "(VHA)"
    when "va_benefits_facility"
      return "(BVA)" if facility_id == "vba_372"

      determine_vba_facility_type
    else
      ""
    end
  end

  def determine_vba_facility_type
    classification&.include?("Regional") ? "(RO)" : "(VBA)"
  end

  def formatted_location
    # Format location in 'City, State, (Facility Type)' format
    # for filter values on the frontend (see: AppealHearingsTable)
    "#{city}, #{state} #{formatted_facility_type}"
  end
end
