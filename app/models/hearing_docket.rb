# A HearingDocket is a grouping of hearings by a date, type and regional_office_key
class HearingDocket
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_writer :slots
  attr_accessor :scheduled_for, :readable_request_type, :request_type, :regional_office_names, :hearings, :user
  attr_accessor :master_record, :hearings_count, :regional_office_key

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
      methods: [:regional_office_names, :slots]
    )
  end

  def slots
    ro_staff = VACOLS::Staff.find_by(stafkey: regional_office_key)
    @slots ||= HearingDayRepository.slots_based_on_type(
      staff: ro_staff,
      type: request_type,
      date: scheduled_for
    ) || SLOTS_BY_TIMEZONE[HearingMapper.timezone(regional_office_key)]
  end

  def attributes
    {
      scheduled_for: scheduled_for,
      request_type: request_type,
      master_record: master_record,
      hearings_count: hearings_count,
      readable_request_type: readable_request_type
    }
  end

  class << self
    def from_hearings(hearings)
      new(
        scheduled_for: hearings.min_by(&:scheduled_for).scheduled_for,
        readable_request_type: hearings.first.readable_request_type,
        hearings: hearings,
        regional_office_names: hearings.map(&:regional_office_name).uniq,
        regional_office_key: hearings.first.regional_office_key,
        master_record: hearings.first.master_record,
        hearings_count: hearings.count
      )
    end
  end
end
