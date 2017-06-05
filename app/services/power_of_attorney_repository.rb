class PowerOfAttorneyRepository
  include PowerOfAttorneyMapper

  # :nocov:
  def self.poa_query(poa)
    VACOLS::Case.includes(:representative).find(poa.vacols_id)
  end
  # :nocov:

  # returns either the data or false
  def self.load_vacols_data(poa)
    case_record = MetricsService.record("VACOLS POA: load_vacols_data #{poa.vacols_id}",
                                        service: :vacols,
                                        name: "PowerOfAttorneyRepository.load_vacols_data") do
      poa_query(poa)
    end

    set_vacols_values(poa: poa, case_record: case_record)

    true
  rescue ActiveRecord::RecordNotFound
    return false
  end

  def self.set_vacols_values(poa:, case_record:)
    rep_info = get_poa_from_vacols_poa(
      vacols_code: case_record.bfso,
      representative_record: case_record.representative
    )

    poa.assign_from_vacols(
      vacols_representative_type: rep_info[:representative_type],
      vacols_representative_name: rep_info[:representative_name]
    )
  end

  def self.get_vacols_reptype_code(short_name:)
    VACOLS::Case::REPRESENTATIVES.each do |representative|
      return representative[0] if representative[1][:short] == short_name
    end
    nil
  end

  def self.first_last_name?(representative_name:)
    representative_name.split(" ").length == 2 && !representative_name.include?("&")
  end

  def self.first_middle_last_name?(representative_name:)
    representative_name.split(" ").length == 3 && representative_name.split(" ")[1].tr(".", "").length == 1
  end

  # :nocov:
  def self.update_vacols_rep_type!(case_record:, vacols_rep_type:)
    VACOLS::Representative.update_vacols_rep_type!(case_record: case_record, rep_type: vacols_rep_type)
  end

  def self.update_vacols_rep_name!(case_record:, first_name:, middle_initial:, last_name:)
    VACOLS::Representative.update_vacols_rep_name!(
        case_record: case_record,
        first_name: first_name,
        middle_initial: middle_initial,
        last_name: last_name
    )
  end

  def self.update_vacols_rep_address_one!(case_record:, address_one:)
    VACOLS::Representative.update_vacols_rep_address_one!(
        case_record: case_record,
        address_one: address_one
    )
  end
  # :nocov:

  def self.update_vacols_rep_table(appeal:, representative_name:)
    if first_last_name?(representative_name: representative_name)
      update_vacols_rep_name!(
          case_record: appeal.case_record,
          first_name: representative_name.split(" ")[0],
          middle_initial: "",
          last_name: representative_name.split(" ")[1]
      )
    elsif first_middle_last_name?(representative_name: representative_name)
      update_vacols_rep_name!(
          case_record: appeal.case_record,
          first_name: representative_name.split(" ")[0],
          middle_initial: representative_name.split(" ")[1],
          last_name: representative_name.split(" ")[2]
      )
    else
      update_vacols_rep_address_one!(
          case_record: appeal.case_record,
          address_one: representative_name
      )
    end
  end

  def self.update_vacols_rep_info!(appeal:, representative_type:, representative_name:)
    if representative_type == "Service Organization"
      # We set the rep type to the service organization name, unless we don't have a record
      # of it. Then we set it to 'other'.
      vacols_rep_type = get_vacols_reptype_code(short_name: representative_name) ||
          get_vacols_reptype_code(short_name: "Other")
    else
      vacols_rep_type = get_vacols_reptype_code(short_name: representative_type)
    end
    update_vacols_rep_type!(case_record: appeal.case_record, vacols_rep_type: vacols_rep_type)

    if %w(T U O).include? vacols_rep_type
      # We only update representative table if the vacols_rep_type is attorney, agent, or other.
      update_vacols_rep_table(appeal: appeal, representative_name: representative_name)
    end
  end
end
