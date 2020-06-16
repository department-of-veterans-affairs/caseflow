# frozen_string_literal: true

module PowerOfAttorneyMapper
  include AddressMapper

  # This is here so when we include this module
  # in classes (e.g. in PoaRepository),
  # the class itself and not just its instance
  # get the methods from this class.
  def self.included(base)
    base.extend(PowerOfAttorneyMapper)
  end

  # parse the BGS claimants.find_poa_by_file_number response
  def get_claimant_poa_from_bgs_claimants_poa(bgs_record = {})
    bgs_record ||= {}
    return {} unless bgs_record.dig(:relationship_name)

    {
      participant_id: bgs_record[:person_org_ptcpnt_id],
      representative_name: bgs_record[:person_org_name],
      representative_type: BGS_REP_TYPE_TO_REP_TYPE.dig(bgs_record[:person_organization_name]) || "Other",
      authzn_change_clmant_addrs_ind: bgs_record[:authzn_change_clmant_addrs_ind],
      authzn_poa_access_ind: bgs_record[:authzn_poa_access_ind],
      veteran_participant_id: bgs_record[:veteran_ptcpnt_id]
    }
  end

  # used by fetch_poas_by_participant_id (for User)
  def get_poa_from_bgs_poa(bgs_rep = {})
    return {} unless bgs_rep&.dig(:org_type_nm)

    bgs_type = bgs_rep[:org_type_nm]
    {
      representative_type: BGS_REP_TYPE_TO_REP_TYPE[bgs_type] || "Other",
      representative_name: bgs_rep[:nm],
      # Used to find the POA address
      participant_id: bgs_rep[:ptcpnt_id]
    }
  end

  # used by fetch_poas_by_participant_ids (for Claimants)
  # and fetch_poa_by_file_number
  def get_claimant_poa_from_bgs_poa(bgs_record = {})
    return {} unless bgs_record.dig(:power_of_attorney)

    bgs_rep = bgs_record[:power_of_attorney]
    bgs_type = bgs_rep[:org_type_nm]
    {
      representative_type: BGS_REP_TYPE_TO_REP_TYPE[bgs_type] || "Other",
      representative_name: bgs_rep[:nm],
      # Used to find the POA address
      participant_id: bgs_rep[:ptcpnt_id],
      # pass through other attrs
      authzn_change_clmant_addrs_ind: bgs_rep[:authzn_change_clmant_addrs_ind],
      authzn_poa_access_ind: bgs_rep[:authzn_poa_access_ind],
      legacy_poa_cd: bgs_rep[:legacy_poa_cd],
      file_number: bgs_record[:file_number],
      claimant_participant_id: bgs_record[:ptcpnt_id]
    }
  end

  def get_hash_of_poa_from_bgs_poas(bgs_resp)
    [bgs_resp].flatten.each_with_object({}) do |poa, hsh|
      hsh[poa[:ptcpnt_id]] = get_claimant_poa_from_bgs_poa(poa)
    end
  end

  def get_limited_poas_hash_from_bgs(bgs_response)
    return unless bgs_response

    limited_poas_hash = {}

    Array.wrap(bgs_response).map do |lpoa|
      limited_poas_hash[lpoa[:bnft_claim_id]] = {
        limited_poa_code: lpoa[:poa_cd],
        limited_poa_access: lpoa[:authzn_poa_access_ind]
      }
    end

    limited_poas_hash
  end

  def get_rep_name_from_rep_record(rep_record)
    return if !rep_record || (rep_record.repfirst.blank? && rep_record.replast.blank?)

    [rep_record.repfirst, rep_record.repmi, rep_record.replast, rep_record.repsuf].select(&:present?).join(" ").strip
  end

  def get_poa_from_vacols_poa(vacols_code:, representative_record: nil)
    if vacols_code.blank? || get_short_name(vacols_code).blank?
      # If VACOLS doesn't have a rep code in its dropdown,
      # it still may have a representative name in the REP table
      # so let's grab that if we can, since we want to show all
      # the information we have.
      {
        representative_name: get_rep_name_from_rep_record(representative_record),
        representative_address: get_address_from_rep_entry(representative_record),
        # TODO: alex to map rep.repso and rep.reptype based on values provided by Jed.
        representative_type: nil
      }
    elsif get_short_name(vacols_code) == "None"
      { representative_type: "None" }
    elsif !rep_name_found_in_rep_table?(vacols_code)
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
        representative_address: get_address_from_rep_entry(representative_record),
        representative_type: get_short_name(vacols_code)
      }
    end
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
