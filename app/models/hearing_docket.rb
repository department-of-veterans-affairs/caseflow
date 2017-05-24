# A HearingDocket is a grouping of hearings by a date, type and regional_office_key
class HearingDocket
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :date, :type, :venue, :hearings, :user

  def to_hash
    serializable_hash(
      include: [:hearings],
      methods: [:venue]
    )
  end

  def attributes
    {
      date: date,
      type: type
    }
  end

  class << self
    def upcoming_for_judge(user)
      from_hearing_groups(hearing_groups_for_judge(user)).sort_by(&:date)
    end

    private

    def from_hearing_groups(hearing_groups)
      hearing_groups.map do |_date, hearings|
        new(
          date: hearings.first.date,
          type: hearings.first.type,
          venue: hearings.first.venue,
          hearings: hearings,
          user: hearings.first.user
        )
      end
    end

    def hearing_groups_for_judge(user)
      hearings_for_judge(user).group_by { |h| h.date.to_i }
    end

    def hearings_for_judge(user)
      Hearing.repository.upcoming_hearings_for_judge(user.vacols_id, date_diff: 7.years)
    end
  end
end
