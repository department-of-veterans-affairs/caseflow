class Judge
  attr_reader :user
  def initialize(user)
    @user = user
  end

  def upcoming_dockets
    @upcoming_dockets ||= upcoming_hearings_grouped_by_date.map do |_date, hearings|
      HearingDocket.from_hearings(hearings)
    end.sort_by(&:date)
  end

  private

  def upcoming_hearings_grouped_by_date
    upcoming_hearings.group_by { |h| h.date.to_i }
  end

  def upcoming_hearings
    Hearing.repository.upcoming_hearings_for_judge(user.vacols_id)
  end
end
