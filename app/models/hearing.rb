class Hearing < ApplicationRecord
  belongs_to :hearing_day
  belongs_to :appeal
  belongs_to :judge, class_name: "User"

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/

  def self.find_hearing_by_uuid_or_vacols_id(id)
    if UUID_REGEX.match?(id)
      find_by_uuid!(id)
    else
      LegacyHearing.find_by!(vacols_id: id)
    end
  end

  def external_id
    uuid
  end
end
