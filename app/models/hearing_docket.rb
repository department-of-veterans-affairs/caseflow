# A HearingDocket is a grouping of hearings by a date, type and regional_office_key
class HearingDocket
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_writer :slots
  attr_accessor :scheduled_for, :readable_request_type, :request_type, :regional_office_names, :hearings, :user
  attr_accessor :master_record, :hearings_count, :regional_office_key

  SLOTS_BY_TIMEZONE = {
    "America/New_York" => 12,
    "America/Chicago" => 10,
    "America/Indiana/Indianapolis" => 12,
    "America/Kentucky/Louisville" => 12,
    "America/Denver" => 10,
    "America/Los_Angeles" => 8,
    "America/Boise" => 10,
    "America/Puerto_Rico" => 12,
    "Asia/Manila" => 8,
    "Pacific/Honolulu" => 8,
    "America/Anchorage" => 8
  }.freeze

  def to_hash
    serializable_hash(
      methods: [:regional_office_names, :slots]
    )
  end

  def slots
    @slots ||= SLOTS_BY_TIMEZONE[HearingMapper.timezone(regional_office_key)]
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
