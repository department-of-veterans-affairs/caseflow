module PowerOfAttorneyMapper
  # This is here so when we include this module
  # in classes (e.g. in PoaRepository),
  # the class itself and not just its instance
  # get the methods from this class.
  def self.included(base)
    base.extend(PowerOfAttorneyMapper)
  end

  def get_poa_from_bgs_poa(bgs_rep = {})
    return {} unless bgs_rep[:power_of_attorney]

    bgs_type = bgs_rep[:power_of_attorney][:org_type_nm]
    {
      representative_type: BGS_REP_TYPE_TO_REP_TYPE[bgs_type] || "Other",
      representative_name: bgs_rep[:power_of_attorney][:nm],
      # Used to find the POA address
      participant_id: bgs_rep[:power_of_attorney][:ptcpnt_id]
    }
  end

  def get_rep_name_from_rep_record(rep_record)
    return if !rep_record || (rep_record.repfirst.blank? && rep_record.replast.blank?)
    "#{rep_record.repfirst} #{rep_record.repmi} #{rep_record.replast} #{rep_record.repsuf}".strip
  end

  def get_poa_from_vacols_poa(vacols_code:, representative_record: nil)
    case
    when vacols_code.blank? || get_short_name(vacols_code).blank?
      # If VACOLS doesn't have a rep code in its dropdown,
      # it still may have a representative name in the REP table
      # so let's grab that if we can, since we want to show all
      # the information we have.
      {
        representative_name: get_rep_name_from_rep_record(representative_record),
        representative_type: nil
      }
    when get_short_name(vacols_code) == "None"
      { representative_type: "None" }
    when !rep_name_found_in_rep_table?(vacols_code)
      # VACOLS lists many Service Organizations by name in the dropdown.
      # If the selection is one of those, use that as the rep name.
      {
        representative_name: get_full_name(vacols_code),
        representative_type: "Service Organization"
      }
    else
      # Otherwise we have to look up the specific name of the rep
      # in the REP table.
      {
        representative_name: get_rep_name_from_rep_record(representative_record),
        representative_type: get_short_name(vacols_code)
      }
    end
  end

  def get_vacols_rep_code_from_poa(rep_type, rep_name)
    if rep_type == "Service Organization" || rep_type == "ORGANIZATION"
      # If the rep name is found in either our VACOLS or BGS objects that map rep name to code,
      # return that. Otherwise, return "O", meaning "Other Service Organization."
      return get_vacols_code_from_vacols_map(rep_name) ||
        get_vacols_code_from_bgs_map(rep_name) ||
        "O"
    end

    # Otherwise, the vacols code may be e.g. "Attorney",so look it up using the rep type.
    return get_vacols_code_from_vacols_map(rep_type)
  end

  def get_vacols_code_from_vacols_map(rep)
    VACOLS::Case::REPRESENTATIVES.select { |_key, value| value[:short] == rep }.keys[0]
  end

  def get_vacols_code_from_bgs_map(rep)
    BGS_REP_NAMES_TO_VACOLS_REP_CODES[rep]
  end

  def rep_name_found_in_rep_table?(vacols_code)
    !!vacols_representatives[vacols_code][:rep_name_in_rep_table]
  end

  private

  def vacols_representatives
    VACOLS::Case::REPRESENTATIVES
  end

  def get_short_name(vacols_code)
    return if vacols_representatives[vacols_code].blank?
    vacols_representatives[vacols_code][:short]
  end

  def get_full_name(vacols_code)
    return if vacols_representatives[vacols_code].blank?
    vacols_representatives[vacols_code][:full_name]
  end

  # TODO: fill out this hash for "Other" and "No Representative"
  BGS_REP_TYPE_TO_REP_TYPE = {
    "POA Attorney" => "Attorney",
    "POA Agent" => "Agent",
    "POA Local/Regional Organization" => "Service Organization",
    "POA State Organization" => "Service Organization",
    "POA National Organization" => "Service Organization"
  }.freeze

  BGS_REP_NAMES_TO_VACOLS_REP_CODES = {
    "AMERICAN LEGION" => "A",
    "AMVETS" => "B",
    "AMERICAN RED CROSS" => "C",
    "DISABLED AMERICAN VETERANS" => "D",
    "JEWISH WAR VETERANS OF THE US" => "E",
    "MILITARY ORDER OF THE PURPLE HEART" => "F",
    "PARALYZED VETERANS OF AMERICA" => "G",
    "VETERANS OF FOREIGN WARS OF THE US" => "H",
    # skip "I" - "State Service Organization(s)" - not a specific organization
    "MARYLAND DEPT OF VETERANS AFFAIRS" => "J", # in Vacols, "Maryland Veterans Commission"
    "VIRGINIA DEPARTMENT OF VETERANS SERVICES" => "K", # In Vacols, "Virginia Department of Veterans Affairs"
    # skip "L" - "No Representative"
    "NAVY MUTUAL AID ASSOCIATION" => "M",
    "NONCOMMISSIONED OFFICERS ASSOCIATION" => "N",
    # skip "O" - "Other Service Organization"
    # "P" - Army & Air Force Mutual Aid Assn. - cannot find it in the BGS POA list
    "CATHOLIC WAR VETERANS OF THE USA" => "Q",
    "FLEET RESERVE ASSOCIATION" => "R",
    "MARINE CORPS LEAGUE" => "S",
    # skip "T" - "Attorney"
    # skip "U" - "Agent"
    "VIETNAM VETERANS OF AMERICA" => "V",
    # skip "W" - "One Time Representative"
    "AMERICAN EX-PRISONERS OF WAR, INC." => "X", # yes, it has a period
    "BLINDED VETERANS ASSOCIATION" => "Y",
    "NATIONAL VETERANS LEGAL SERVICES PROGRAM" => "Z",
    "NATIONAL VETERANS ORGANIZATION OF AMERICA, INC." => "1",
    "WOUNDED WARRIOR PROJECT" => "2"
  }.freeze
end
