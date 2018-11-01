module AppealConcern
  extend ActiveSupport::Concern

  delegate :station_key, to: :regional_office

  def regional_office
    @regional_office ||= RegionalOffice.find!(regional_office_key)
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

  def veteran_full_address
    "#{veteran.address_line_1} #{veteran.address_line_2} #{veteran.city}, #{veteran.state} #{veteran.zip}"
  end

  def veteran_mi_formatted
    if veteran_middle_initial
      veteran_name_object.formatted(:readable_mi_formatted)
    else
      veteran_name_object.formatted(:readable_short)
    end
  end

  def veteran_fi_last_formatted
    veteran_name_object.formatted(:readable_fi_last_formatted)
  end

  def appellant_name
    if appellant_first_name
      [appellant_first_name, appellant_middle_initial, appellant_last_name].select(&:present?).join(" ")
    end
  end

  def appellant_mi_formatted
    if appellant_middle_initial
      appellant_name_object.formatted(:readable_mi_formatted)
    else
      appellant_name_object.formatted(:readable_short)
    end
  end

  def appellant_last_first_mi
    # returns appellant name in format <last>, <first> <middle_initial>.
    if appellant_first_name
      name = "#{appellant_last_name}, #{appellant_first_name}"
      name.concat " #{appellant_middle_initial}." if appellant_middle_initial
    end
  end

  def closest_alternate_hearing_location
    lat_lng = Appeal.vets360_service.geocode(veteran_full_address)
    Appeal.facilities_locator_service.get_closest(lat_lng)[:data][0]
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
