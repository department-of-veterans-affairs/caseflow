class Judge
  attr_reader :user
  def initialize(user)
    @user = user
  end

  def upcoming_dockets
    @upcoming_dockets ||= upcoming_hearings_grouped_by_date.map do |_date, hearings|
      HearingDocket.from_hearings(hearings)
    end
  end

  def docket(date)
    @docket ||= upcoming_hearings_on(date).map do |hearing|
      {
        id: hearing.id,
        vbms_id: hearing.appeal.vbms_id,
        vacols_id: hearing.vacols_id,
        date: hearing.date,
        type: hearing.request_type,
        venue: hearing.venue,
        appellant: hearing.appellant_name,
        representative: hearing.appeal.representative
      }
    end
  end

  private

  def upcoming_hearings_grouped_by_date
    upcoming_hearings.group_by { |h| h.date.beginning_of_day.to_i }
  end

  def upcoming_hearings_on(date)
    upcoming_hearings.select do |hearing|
      hearing.date.between?(date, date.end_of_day)
    end
  end

  def upcoming_hearings
    Hearing.repository.upcoming_hearings_for_judge(user.vacols_id).sort_by(&:date)
  end
end
