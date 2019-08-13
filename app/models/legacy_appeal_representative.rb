# frozen_string_literal: true

class LegacyAppealRepresentative
  def initialize(power_of_attorney:, case_record:)
    @power_of_attorney = power_of_attorney
    @case_record = case_record
  end

  # This references VACOLS::Representative table
  delegate :vacols_representatives, to: :case_record

  # This references Caseflow organizations table
  def representatives
    Representative.where(participant_id: [representative_participant_id] - [nil])
  end

  def representative_participant_id
    power_of_attorney.bgs_participant_id
  end

  REPRESENTATIVE_METHOD_NAMES = [
    :representative_name,
    :representative_type,
    :representative_address
  ].freeze

  REPRESENTATIVE_METHOD_NAMES.each do |method_name|
    define_method(method_name) do
      if use_representative_info_from_bgs?
        power_of_attorney.public_send("bgs_#{method_name}".to_sym)
      else
        power_of_attorney.public_send("vacols_#{method_name}".to_sym)
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

  attr_reader :power_of_attorney, :case_record

  def use_representative_info_from_bgs?
    RequestStore.store[:application] == "queue" ||
      RequestStore.store[:application] == "hearings" ||
      RequestStore.store[:application] == "idt"
  end

  def vacols_representative_code
    power_of_attorney.vacols_representative_code
  end
end
