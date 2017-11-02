module AppealConcern
  extend ActiveSupport::Concern

  delegate :station_key, to: :regional_office

  def regional_office
    # TODO: We should probably use RegionalOffice.find! here since it
    #       would be truly exceptional if the RO didn't exist
    @regional_office ||= RegionalOffice.new(regional_office_key)
  end

  def regional_office_name
    "#{regional_office.city}, #{regional_office.state}"
  end

  def veteran_name
    veteran_name_object.formatted(:form)
  end

  def veteran_full_name
    veteran_name_object.formatted(:readable_full)
  end

  def appellant_name
    if appellant_first_name
      [appellant_first_name, appellant_middle_initial, appellant_last_name].select(&:present?).join(", ")
    end
  end

  def appellant_last_first_mi
    # returns appellant name in format <last>, <first> <middle_initial>.
    if appellant_first_name
      name = "#{appellant_last_name}, #{appellant_first_name}"
      name.concat " #{appellant_middle_initial}." if appellant_middle_initial
    end
  end

  private

  # TODO: this is named "veteran_name_object" to avoid name collision, refactor
  # the naming of the helper methods.
  def veteran_name_object
    FullName.new(veteran_first_name, veteran_middle_initial, veteran_last_name)
  end
end
