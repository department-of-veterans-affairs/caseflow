class Judge
  attr_reader :user
  def initialize(user)
    @user = user
  end

  def upcoming_dockets
    @upcoming_dockets ||= upcoming_hearings_grouped_by_date.transform_values do |hearings|
      HearingDocket.from_hearings(hearings)
    end
  end

  def docket?(date)
    return true if upcoming_hearings_on(date).count > 0
  end

  private

  def upcoming_hearings_grouped_by_date
    upcoming_hearings.group_by { |h| h.date.strftime("%F") }
  end

  def upcoming_hearings
    Hearing.repository.upcoming_hearings_for_judge(user.vacols_id).sort_by(&:date)
  end

  def upcoming_hearings_on(date)
    upcoming_hearings.select do |hearing|
      hearing.date.between?(date, date.end_of_day)
    end
  end
end
