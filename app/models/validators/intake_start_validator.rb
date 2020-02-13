# frozen_string_literal: true

class IntakeStartValidator
  def initialize(intake:)
    @intake = intake
  end

  def validate
    return false unless validate_file_number

    validate_veteran
    validate_intake

    !intake.error_code
  end

  private

  attr_reader :intake

  delegate :veteran_file_number, :veteran, :error_code, :errors, to: :intake

  def validate_veteran
    if !veteran
      intake.error_code = :veteran_not_found
    elsif !veteran.accessible?
      set_veteran_accessible_error
    elsif !user_may_modify_veteran_file?
      intake.error_code = :veteran_not_modifiable
    elsif veteran.incident_flash?
      intake.error_code = :incident_flash
    elsif duplicate_veteran_records_in_corpdb
      intake.error_code = :veteran_has_duplicate_records_in_corpdb
    end
  end

  def validate_intake
    if duplicate_intake_in_progress
      intake.error_code = :duplicate_intake_in_progress
      intake.store_error_data(processed_by: duplicate_intake_in_progress.user.full_name)
    end
  end

  def validate_file_number
    if !file_number_valid?
      intake.error_code = :invalid_file_number
    elsif file_number_reserved?
      intake.error_code = :reserved_veteran_file_number
    end

    !error_code
  end

  def set_veteran_accessible_error
    return if veteran.accessible?

    intake.error_code = veteran.multiple_phone_numbers? ? :veteran_has_multiple_phone_numbers : :veteran_not_accessible
  end

  def duplicate_veteran_records_in_corpdb
    return false unless FeatureToggle.enabled?(:alert_duplicate_veterans, user: RequestStore[:current_user])

    pids = DuplicateVeteranParticipantIDFinder.new(veteran: veteran).call
    if pids.count > 1
      intake.store_error_data(pids: pids)
      return true
    end
    false
  end

  def duplicate_intake_in_progress
    @duplicate_intake_in_progress ||=
      Intake.in_progress.find_by(type: intake.type, veteran_file_number: veteran_file_number)
  end

  def file_number_valid?
    return false unless veteran_file_number

    veteran_file_number =~ /^[0-9]{8,9}$/
  end

  def file_number_reserved?
    Rails.deploy_env?(:prod) && veteran_file_number == "123456789"
  end

  def user_may_modify_veteran_file?
    return true if intake.user == User.api_user

    bgs = BGSService.new
    return false unless bgs.can_access?(veteran_file_number)

    # BVA has indicated that station conflict policy doesn't apply to Appeals.
    # See https://github.com/department-of-veterans-affairs/caseflow/issues/13165
    # This bypass is behind the :allow_same_station_appeals feature toggle for now.
    return true if FeatureToggle.enabled?(:allow_same_station_appeals, user: intake.user) && intake.is_a?(AppealIntake)

    !bgs.station_conflict?(veteran_file_number, veteran.participant_id)
  end
end
