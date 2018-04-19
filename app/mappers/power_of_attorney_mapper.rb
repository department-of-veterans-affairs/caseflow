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
