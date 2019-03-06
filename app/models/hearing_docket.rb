# frozen_string_literal: true

# A HearingDocket is a grouping of hearings by a date, type and regional_office_key
class HearingDocket
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_writer :slots
  attr_accessor :scheduled_for, :readable_request_type, :request_type, :regional_office_names, :hearings, :user
  attr_accessor :master_record, :hearings_count, :regional_office_key

  def to_hash
    serializable_hash(
      methods: [:regional_office_names, :slots]
    )
  end

  def slots
    @slots ||= HearingDay::SLOTS_BY_TIMEZONE[HearingMapper.timezone(regional_office_key)]
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
