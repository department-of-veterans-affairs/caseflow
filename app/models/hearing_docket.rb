# A HearingDocket is a grouping of hearings by a date, type and regional_office_key
class HearingDocket
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :date, :type, :regional_office_key, :hearings

  def to_hash
    serializable_hash(
      include: [:hearings],
      methods: [:regional_office]
    )
  end

  def attributes
    {
      date: date,
      type: type
    }
  end

  def regional_office
    VACOLS::RegionalOffice::CITIES[regional_office_key]
  end

  class << self
    def for_judge(user)
      Appeal.repository
            .hearings(user.vacols_id)
            .group_by { |h| h.date.to_i }
            .map do |date, hearings|
        new(
          date: hearings.first.date.to_s(:json_date),
          type: hearings.first.type,
          regional_office_key: hearings.first.regional_office_key,
          hearings: hearings
        )
      end
    end
  end
end
