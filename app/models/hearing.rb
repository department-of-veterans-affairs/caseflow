class Hearing < ApplicationRecord
  belongs_to :hearing_day
  belongs_to :appeal
  belongs_to :judge, class_name: "User"

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze

  delegate :scheduled_for, to: :hearing_day
  delegate :request_type, to: :hearing_day

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

  #:nocov:
  # This is all fake data that will be refactored in a future PR.
  def regional_office_key
    "RO19"
  end

  def regional_office_name
    "Winston-Salem, NC"
  end

  def type
    request_type
  end
  #:nocov:

  def external_id
    uuid
  end

  def to_hash_for_worksheet(_current_user_id)
    serializable_hash(methods: :external_id)
  end
end
