# frozen_string_literal: true

class HearingsForAppeal
  def initialize(appeal_id)
    @appeal_id = appeal_id
  end

  # This method is optimized to avoid calling VACOLS for legacy appeals.
  def held_hearings
    if Appeal::UUID_REGEX.match?(appeal_id)
      Appeal.find_by_uuid!(appeal_id).hearings.where(disposition: Constants.HEARING_DISPOSITION_TYPES.held)
    else
      # Assumes that an appeal exists in VACOLS if there are hearings
      # for it.
      legacy_hearings = HearingRepository.hearings_for_appeal(appeal_id)

      # If there are no hearings for the VACOLS id, maybe the case doesn't
      # actually exist? This is SLOW! Only load VACOLS data if the Legacy Appeal
      # doesn't exist in Caseflow. `LegacyAppeal.find_or_create_by_vacols_id` will
      # ALWAYS load data from VACOLS.
      LegacyAppeal.find_or_create_by_vacols_id(appeal_id) if legacy_hearings.empty? && !LegacyAppeal.exists?(appeal_id)

      legacy_hearings.select do |hearing|
        hearing.disposition.to_s == Constants.HEARING_DISPOSITION_TYPES.held
      end
    end
  end

  private

  attr_reader :appeal_id
end
