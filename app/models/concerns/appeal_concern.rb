# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module AppealConcern
  extend ActiveSupport::Concern

  delegate :station_key, to: :regional_office

  included do
    if ancestors.include?(ApplicationRecord)
      has_many :attorney_case_reviews, -> { order(:created_at) }, as: :appeal
      has_many :judge_case_reviews, -> { order(:created_at) }, as: :appeal
    end
  end

  def latest_attorney_case_review
    attorney_case_reviews.last
  end

  def latest_judge_case_review
    judge_case_reviews.last
  end

  def regional_office
    return nil if regional_office_key.nil?

    @regional_office ||= begin
                           RegionalOffice.find!(regional_office_key)
                         rescue RegionalOffice::NotFoundError
                           nil
                         end
  end

  def regional_office_name
    return if regional_office.nil?

    "#{regional_office.city}, #{regional_office.state}"
  end

  def closest_regional_office_label
    return if closest_regional_office.nil?

    return "Central Office" if closest_regional_office == "C"

    RegionalOffice.find!(closest_regional_office).name
  end

  def veteran_name
    veteran_name_object.formatted(:form)
  end

  def veteran_full_name
    veteran_name_object.formatted(:readable_full)
  end

  def veteran_fi_last_formatted
    veteran_name_object.formatted(:readable_fi_last_formatted)
  end

  def appellant_name
    if appellant_first_name
      [appellant_first_name, appellant_middle_initial, appellant_last_name].select(&:present?).join(" ")
    end
  end

  # JOHN S SMITH => John S Smith
  def appellant_fullname_readable
    appellant_name&.titleize
  end

  def appellant_last_first_mi
    # returns appellant name in format <last>, <first> <middle_initial>.
    if appellant_first_name
      name = "#{appellant_last_name}, #{appellant_first_name}"
      "#{name} #{appellant_middle_initial}." if appellant_middle_initial
    end
  end

  def appellant_or_veteran_name
    return appellant_fullname_readable if appellant_is_not_veteran

    veteran_full_name
  end

  def appellant_tz
    timezone_identifier_for_address(appellant_address)
  end

  def representative_tz
    timezone_identifier_for_address(representative_address)
  end

  def accessible?
    # this is used for calling BGSService.can_access? to fix VSO access that is being blocked
    # by BGS returning false for veteran.accessible? when they should indeed have access to the appeal.
    # does this VSO have access to this appeal? check if current user is one of the reps on the appeal.
    # if so return true, if not then do the BgsService.can_access? path.
    user = RequestStore[:current_user]
    assigned_to_vso?(user) || user_represents_claimant_not_veteran?(user) || bgs.can_access?(veteran_file_number)
  end

  # :reek:FeatureEnvy
  def assigned_to_vso?(user)
    # copied from hearing model and should be renamed and/or consolidated with assigned_to_vso_user?
    # since this is technically a user validation
    tasks.any? do |task|
      task.type == TrackVeteranTask.name &&
        task.assigned_to.is_a?(Representative) &&
        task.assigned_to.user_has_access?(user) &&
        task.open?
    end
  end

  def user_represents_claimant_not_veteran?(user)
    appellant_is_not_veteran && representatives.any? { |rep| rep.user_has_access?(user) }
  end

  #
  # This section was added to deal with displaying FNOD information in various places.
  # Currently, the FNOD information is used by both queue and hearings in:
  # - FnodBanner.jsx
  # - FnodBadge.jsx
  #
  # veteran_is_not_claimant is implemented differently in Appeal and LegacyAppeal
  # - Appeal: The result depends on 'veteran_is_not_claimant' field in the caseflow DB
  # - LegacyAppeal: The result depends on if 'appellant_first_name' exists in VACOLS

  def appellant_is_veteran
    !veteran_is_not_claimant
  end

  def veteran_is_deceased
    veteran_death_date.present?
  end

  def veteran_appellant_deceased?
    veteran_is_deceased && appellant_is_veteran
  end

  def veteran_death_date
    veteran&.date_of_death
  end

  def veteran_death_date_reported_at
    veteran&.date_of_death_reported_at
  end

  # End FNOD section

  private

  # TODO: this is named "veteran_name_object" to avoid name collision, refactor
  # the naming of the helper methods.
  def veteran_name_object
    FullName.new(veteran_first_name, veteran_middle_initial, veteran_last_name)
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
  def timezone_identifier_for_address(addr)
    return if addr.blank?

    address_obj = addr.is_a?(Hash) ? Address.new(addr) : addr

    # Some appellant addresses have empty country values but valid city, state, and zip codes.
    # If the address has a zip code then we make the best guess that the address is within the US
    # (TimezoneService.address_to_timezone will raise an error if this guess is wrong and the zip
    # code is not a valid US zip code), otherwise we return nil without attempting to get
    # thetimezone identifier.
    if address_obj.country.blank?
      return if address_obj.zip.blank?

      new_address_hash = address_obj.as_json.symbolize_keys.merge(country: "USA")
      address_obj = Address.new(**new_address_hash)
    end

    # APO/FPO/DPO addresses do not have time zones so we don't attempt to fetch them.
    return if address_obj.military_or_diplomatic_address?

    begin
      TimezoneService.address_to_timezone(address_obj).identifier
    rescue TimezoneService::AmbiguousTimezoneError => error
      # TimezoneService raises an error for foreign countries that span multiple time zones since we
      # only look up time zones by country for foreign addresses. We do not act on these errors (they
      # are valid addresses, we just cannot determine the time zone) so we do not send the error to
      # Sentry, only to Datadog for trend tracking.
      DataDogService.increment_counter(
        metric_group: "appeal_timezone_service",
        metric_name: "ambiguous_timezone_error",
        app_name: RequestStore[:application],
        attrs: {
          country_code: error.country_code
        }
      )
      nil
    rescue StandardError => error
      Raven.capture_exception(error)
      nil
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength
end
# rubocop:enable Metrics/ModuleLength
