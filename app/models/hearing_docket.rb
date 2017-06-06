# A HearingDocket is a grouping of hearings by a date, type and regional_office_key
class HearingDocket
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :date, :type, :venue, :hearings, :user

  class NoDocket < StandardError; end

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
      upcoming_dockets(user).map do |_date, hearings|
        from_hearings(hearings)
      end.sort_by(&:date)
    end

    def docket_for_judge(user, date)
      date_parts = date.split("-").map(&:to_i)
      beg_of_day = Time.zone.local(date_parts[0], date_parts[1], date_parts[2])
      end_of_day = Time.zone.local(date_parts[0], date_parts[1], date_parts[2] + 1) - 1.second
      docket = upcoming_docket_for(user, beg_of_day, end_of_day).map do |hearing|
        {
          date: hearing.date,
          type: hearing_type(hearing.type),
          venue: hearing.venue,
          appellant: appellant(hearing.appeal),
          appellantId: hearing.appeal.vbms_id,
          representative: hearing.appeal.representative
        }
      end
      docket.sort_by { :date }
    rescue StandardError
      raise NoDocket
    end

    def hearing_type(type)
      type != :central_office ? type.to_s.capitalize : "CO"
    end

    def appellant(appeal)
      "#{appeal.appellant_last_name}, #{appeal.appellant_first_name}"
    end

    private

    def from_hearings(hearings)
      new(
        date: hearings.first.date,
        type: hearings.first.type,
        venue: hearings.first.venue,
        hearings: hearings,
        user: hearings.first.user
      )
    end

    # Returns an array of hearings arrays grouped by date
    def upcoming_dockets(user)
      upcoming_hearings_for_judge(user).group_by { |h| h.date.to_i }
    end

    def upcoming_docket_for(user, beg_of_day, end_of_day)
      upcoming_hearings_for_judge(user).select do |hearing|
        hearing.date.between?(beg_of_day, end_of_day)
      end
    end

    def upcoming_hearings_for_judge(user)
      Hearing.repository.upcoming_hearings_for_judge(user.vacols_id, date_diff: 7.years)
    end
  end
end
