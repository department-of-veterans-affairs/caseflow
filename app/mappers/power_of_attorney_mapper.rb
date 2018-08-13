# rubocop:disable Metrics/ModuleLength
module PowerOfAttorneyMapper
  # TODO: break this module up into BGS and VACOLS-specific POA parsers
  # This is here so when we include this module
  # in classes (e.g. in PoaRepository),
  # the class itself and not just its instance
  # get the methods from this class.
  def self.included(base)
    base.extend(PowerOfAttorneyMapper)
  end

  def get_poa_from_bgs_poa(bgs_rep = {})
    return {} unless bgs_rep

    bgs_type = bgs_rep[:org_type_nm]
    {
      representative_type: BGS_REP_TYPE_TO_REP_TYPE[bgs_type] || "Other",
      representative_name: bgs_rep[:nm],
      # Used to find the POA address
      participant_id: bgs_rep[:ptcpnt_id]
    }
  end

  def get_poa_from_vacols_poa(vacols_code:, rep_record: {})
    # TODO: refactor to remove the autoloading behavior that requires
    # us to set all these keys, evern if they're empty.
    return none_poa if get_short_name(vacols_code) == "None"
    return none_poa if rep_record.empty? && !vacols_code
    return service_org_poa(vacols_code) if get_full_name(vacols_code) && !rep_name_found_in_rep_table?(vacols_code)
    rep_table_poa(rep_record)
  end

  def rep_table_poa(rep_record)
    {
      vacols_org_name: "",
      vacols_representative_type: VACOLS::Representative.reptype_name_from_code(rep_record.try(:reptype)),
      vacols_first_name: rep_record.try(:repfirst),
      vacols_middle_initial: rep_record.try(:repmi),
      vacols_last_name: rep_record.try(:replast),
      vacols_suffix: rep_record.try(:repsuf)
    }
  end

  def service_org_poa(vacols_code)
    {
      vacols_org_name: get_full_name(vacols_code),
      vacols_representative_type: "Service Organization",
      vacols_first_name: "",
      vacols_middle_initial: "",
      vacols_last_name: "",
      vacols_suffix: ""
    }
  end

  def none_poa
    {
      vacols_org_name: "",
      vacols_representative_type: "None",
      vacols_first_name: "",
      vacols_middle_initial: "",
      vacols_last_name: "",
      vacols_suffix: ""
    }
  end

  def get_vacols_rep_code_from_poa(rep_type, rep_name)
    if rep_type == "Service Organization" || rep_type == "ORGANIZATION"
      # If the rep name is found in either our VACOLS or BGS objects that map rep name to code,
      # return that. Otherwise, return "O", meaning "Other Service Organization."
      return vacols_code_from_vacols_map(rep_name) ||
             vacols_code_from_bgs_map(rep_name) || "O"
    end

    # Otherwise, the vacols code may be e.g. "Attorney", so look it up using the rep type.
    vacols_code_from_vacols_map(rep_type)
  end

  def vacols_code_from_vacols_map(rep)
    VACOLS::Case::REPRESENTATIVES.select { |_key, value| value[:short] == rep || value[:full_name] == rep }.keys[0]
  end

  def vacols_code_from_bgs_map(rep)
    BGS_REP_NAMES_TO_VACOLS_REP_CODES[rep]
  end

  def rep_name_found_in_rep_table?(vacols_code)
    !!vacols_representatives[vacols_code].try(:[], :rep_name_in_rep_table)
  end

  private

  def vacols_representatives
    VACOLS::Case::REPRESENTATIVES
  end

  def get_short_name(vacols_code)
    vacols_representatives[vacols_code].try(:[], :short)
  end

  def get_full_name(vacols_code)
    vacols_representatives[vacols_code].try(:[], :full_name)
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
# rubocop:enable Metrics/ModuleLength
