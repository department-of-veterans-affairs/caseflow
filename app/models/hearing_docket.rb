# A HearingDocket is a grouping of hearings by a date, type and regional_office_key
class HearingDocket
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :date, :type, :regional_office_name, :hearings, :user

  def to_hash
    serializable_hash(
      methods: [:regional_office_name, :hearings_hash]
    )
  end

  def attributes
    {
      date: date,
      type: type
    }
  end

  def hearings_hash
    hearings.map(&:to_hash)
  end

  class << self
    def from_hearings(hearings)
      new(
        date: hearings.first.date,
        type: hearings.first.type,
        hearings: hearings,
        user: hearings.first.user,
        regional_office_name: hearings.first.regional_office_name
      )
    end
  end
end
