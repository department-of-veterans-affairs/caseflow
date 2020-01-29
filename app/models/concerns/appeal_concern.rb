# frozen_string_literal: true

module AppealConcern
  extend ActiveSupport::Concern

  delegate :station_key, to: :regional_office

  def regional_office
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

  def appellant_last_first_mi
    # returns appellant name in format <last>, <first> <middle_initial>.
    if appellant_first_name
      name = "#{appellant_last_name}, #{appellant_first_name}"
      "#{name} #{appellant_middle_initial}." if appellant_middle_initial
    end
  end

  def user_represents_claimant_not_veteran
    return false unless FeatureToggle.enabled?(:vso_claimant_representative)

    appellant_is_not_veteran && representatives.any? { |rep| rep.user_has_access?(current_user) }
  end

  private

  # TODO: this is named "veteran_name_object" to avoid name collision, refactor
  # the naming of the helper methods.
  def veteran_name_object
    FullName.new(veteran_first_name, veteran_middle_initial, veteran_last_name)
  end

  def appellant_name_object
    FullName.new(appellant_first_name, appellant_middle_initial, appellant_last_name)
  end
end
