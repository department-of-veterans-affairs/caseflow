# A HearingDocket is a grouping of hearings by a date, type and regional_office_key
class HearingDocket
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :date, :type, :regional_office_name, :hearings, :user, :regional_office_key
  attr_accessor :master_record, :hearings_count

  SLOTS_BY_TIMEZONE = {
    "America/New_York" => 11,
    "America/Chicago" => 9,
    "America/Indiana/Indianapolis" => 11,
    "America/Kentucky/Louisville" => 11,
    "America/Denver" => 9,
    "America/Los_Angeles" => 7,
    "America/Boise" => 9,
    "America/Puerto_Rico" => 11,
    "Asia/Manila" => 7,
    "Pacific/Honolulu" => 7,
    "America/Anchorage" => 7
  }.freeze

  def to_hash
    serializable_hash(
      methods: %i[regional_office_name slots]
    )
  end

  def attributes
    {
      date: date,
      type: type,
      master_record: master_record,
      hearings_count: hearings_count
    }
  end

  def slots
    HearingDocket.repository.number_of_slots(
      regional_office_key: regional_office_key,
      type: type,
      date: date
    ) || SLOTS_BY_TIMEZONE[HearingMapper.timezone(regional_office_key)]
  end

  class << self
    attr_writer :repository

    def repository
      @repository ||= HearingRepository
    end

    def from_hearings(hearings)
      new(
        date: hearings.sort_by(&:date).first.date,
        type: hearings.first.type,
        hearings: hearings,
        regional_office_name: hearings.first.regional_office_name,
        regional_office_key: hearings.first.regional_office_key,
        master_record: hearings.first.master_record,
        hearings_count: hearings.count
      )
    end
  end
end
