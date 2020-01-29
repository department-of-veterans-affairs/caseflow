# frozen_string_literal: true

class AvailableHearingLocations < ApplicationRecord
  belongs_to :veteran, foreign_key: :file_number, primary_key: :veteran_file_number
  belongs_to :appeal, polymorphic: true

  # this will eventually replace getFacilityType in AppealHearingLocations
  # in upcoming pagination work
  def formatted_facility_type
    case facility_type
    when "vet_center"
      "(Vet Center) "
    when "va_health_facility"
      "(VHA) "
    when "va_benefits_facility"
      return "(BVA) " if facility_id == "vba_372"

      determine_vba_facility_type
    else
      ""
    end
  end

  def determine_vba_facility_type
    classification.include?("Regional") ? "(RO) " : "(VBA) "
  end

  def formatted_location
    # For filter values on the frontend (see: AppealHearingsTable)
    "#{city}, #{state} #{formatted_facility_type}"
  end
end
