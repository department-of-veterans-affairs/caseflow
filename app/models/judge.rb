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

  private

  def upcoming_hearings_grouped_by_date
    upcoming_hearings.group_by { |h| h.date.strftime("%F") }
  end

  def upcoming_hearings
    Hearing.repository.upcoming_hearings_for_judge(user.vacols_id).sort_by(&:date)
  end
end
