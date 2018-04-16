class Judge
  attr_reader :user
  def initialize(user)
    @user = user
  end

  def upcoming_dockets
    @upcoming_dockets ||= upcoming_hearings_grouped_by_date.transform_values do |hearings|
      HearingDocket.from_hearings(hearings)
    end

    # get bulk slots for all the dockets from vacols
    dockets_slots = get_dockets_slots(@upcoming_dockets)

    # assign number of slots to its corresponding docket
    @upcoming_dockets.map do |date, hearing_docket|
      hearing_docket.slots = dockets_slots[date] ||
                             HearingDocket::SLOTS_BY_TIMEZONE[HearingMapper
                               .timezone(hearing_docket.regional_office_key)]
      [date, hearing_docket]
    end.to_h
  end

  def docket?(date)
    upcoming_hearings_on(date).count > 0
  end

  def upcoming_hearings_on(date)
    upcoming_hearings.select do |hearing|
      hearing.date.between?(date, date.end_of_day)
    end
  end

  def attorneys
    (Constants::AttorneyJudgeTeams::JUDGES[user.css_id].try(:[], :attorneys) || []).map do |attorney|
      User.create_from_vacols(css_id: attorney[:css_id], station_id: User::BOARD_STATION_ID, full_name: attorney[:name])
    end
  end

  private

  def upcoming_hearings_grouped_by_date
    upcoming_hearings.group_by { |h| h.date.strftime("%F") }
  end

  def upcoming_hearings
    Hearing.repository.fetch_hearings_for_judge(user.css_id).sort_by(&:date)
  end

  def get_dockets_slots(dockets)
    Hearing.repository.fetch_dockets_slots(dockets)
  end

  class << self
    attr_writer :repository

    def repository
      @repository ||= JudgeRepository
    end

    def list_all
      Rails.cache.fetch("#{Rails.env}_list_of_judges_from_vacols") do
        repository.find_all_judges
      end
    end
  end
end
