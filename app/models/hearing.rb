class Hearing < ApplicationRecord
  belongs_to :hearing_day
  belongs_to :appeal
  belongs_to :judge, class_name: "User"

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze

  delegate :scheduled_for, to: :hearing_day
  delegate :hearing_type, to: :hearing_day

  def self.find_hearing_by_uuid_or_vacols_id(id)
    if UUID_REGEX.match?(id)
      find_by_uuid!(id)
    else
      LegacyHearing.find_by!(vacols_id: id)
    end
  end

  def master_record
    false
  end

  def regional_office_key
    'RO18'
  end

  def regional_office_name
    'RO18'
  end

  def type
    hearing_type
  end

  def external_id
    uuid
  end

  def to_hash_for_worksheet(_current_user_id)
    serializable_hash(methods: :external_id)
  end
end
