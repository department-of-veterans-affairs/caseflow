class LegacyAppealRepresentativeFetcher
  def initialize(veteran_file_number:, vacols_id:, case_record:)
    @veteran_file_number = veteran_file_number
    @vacols_id = vacols_id
    @case_record = case_record
  end

  # This references Caseflow organizations table
  def representatives
    Representative.where(participant_id: [representative_participant_id] - [nil])
  end

  # This references VACOLS::Representative table
  def vacols_representatives
    case_record.vacols_representatives
  end

  REPRESENTATIVE_METHOD_NAMES = [
    :representative_name,
    :representative_type,
    :representative_address
  ].freeze

  REPRESENTATIVE_METHOD_NAMES.each do |method_name|
    define_method(method_name) do
      if use_representative_info_from_bgs?
        power_of_attorney.send("bgs_#{method_name}".to_sym)
      else
        power_of_attorney.send("vacols_#{method_name}".to_sym)
      end
    end
  end

  def representative_to_hash
    {
      name: representative_name,
      type: representative_type,
      code: vacols_representative_code,
      participant_id: representative_participant_id,
      address: representative_address
    }
  end

  private

  attr_reader :veteran_file_number, :vacols_id, :case_record

  def use_representative_info_from_bgs?
    RequestStore.store[:application] == "queue" ||
      RequestStore.store[:application] == "hearings" ||
      RequestStore.store[:application] == "idt"
  end

  def vacols_representative_code
    power_of_attorney.vacols_representative_code
  end

  def representative_participant_id
    power_of_attorney.bgs_participant_id
  end

  def power_of_attorney
    # TODO: this will only return a single power of attorney. There are sometimes multiple values, eg.
    # when a contesting claimant is present. Refactor so we surface all POA data.
    @power_of_attorney ||= PowerOfAttorney.new(file_number: veteran_file_number, vacols_id: vacols_id).tap do |poa|
      # Set the VACOLS properties of the PowerOfAttorney object here explicitly so we only query the database once.
      poa.class.repository.set_vacols_values(
        poa: poa,
        case_record: case_record,
        representative: VACOLS::Representative.appellant_representative(vacols_id)
      )
    end
  end
end
