module PowerOfAttorneyMapper
  # This is here so when we include this module
  # in classes (e.g. in PoaRepository),
  # the class itself and not just its instance
  # get the methods from this class.
  def self.included(base)
    base.extend(PowerOfAttorneyMapper)
  end

  # VACOLS methods
  def vacols_representatives
    VACOLS::Case::REPRESENTATIVES
  end

  def rep_name_found_in_rep_table?(vacols_code)
    !!vacols_representatives[vacols_code][:rep_name_in_rep_table]
  end

  def get_short_name(vacols_code)
    vacols_representatives[vacols_code][:short]
  end

  def get_full_name(vacols_code)
    vacols_representatives[vacols_code][:full_name]
  end

  def get_poa_from_vacols_poa(vacols_code)
    case
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
      # TODO: modify poa repository to look it up and pass that
      # info into this method.
      {
        representative_name: "Stub POA Name",
        representative_type: "Stub POA Type"
      }
    end
  end

  # BGS Methods
  # todo: fill out this hash
  BGS_REP_TYPE_TO_REP_TYPE = {
    "POA Attorney": "Attorney",
    "POA Agent": "Agent",
    "POA Local/Regional Organization": "Service Organization",
    "POA State Organization": "Service Organization"
  }.freeze

  def get_poa_from_bgs_poa(bgs_poa)
    # TODO: what do we do if we encounter a rep type we don't know?
    # TODO: gracefully handle possible cases where bgs poa is nil or unexpected
    bgs_type = bgs_poa[:power_of_attorney][:org_type_nm]
    {
      representative_type: BGS_REP_TYPE_TO_REP_TYPE[bgs_type.to_sym] || "Other",
      representative_name: bgs_poa[:power_of_attorney][:nm]
    }
  end
end
