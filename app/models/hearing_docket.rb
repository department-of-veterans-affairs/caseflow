# A HearingDocket is a grouping of hearings by a date, type and regional_office_key
class HearingDocket
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :date, :type, :regional_office_name, :hearings, :user, :regional_office_key

  def to_hash
    serializable_hash(
      methods: [:regional_office_name, :hearings_array, :slots]
    )
  end

  def attributes
    {
      date: date,
      type: type
    }
  end

  def hearings_array
    hearings.map(&:to_hash)
  end

  def slots
    HearingDocket.repository.number_of_slots(
      regional_office_key: regional_office_key,
      type: type,
      date: date
    )
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
        user: hearings.first.user,
        regional_office_name: hearings.first.regional_office_name,
        regional_office_key: hearings.first.regional_office_key
      )
    end
  end
end
