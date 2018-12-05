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

  def upcoming_hearings_on(date, is_fetching_issues = false)
    upcoming_hearings(is_fetching_issues).select do |hearing|
      hearing.date.between?(date.beginning_of_day, date.end_of_day)
    end
  end

  def attorneys
    JudgeTeam.for_judge(user).try(:attorneys) || []
  end

  private

  def upcoming_hearings_grouped_by_date
    upcoming_hearings.group_by { |h| h.date.strftime("%F") }
  end

  def upcoming_hearings(is_fetching_issues = false)
    Hearing.repository.fetch_hearings_for_judge(user.css_id, is_fetching_issues).sort_by(&:date)
  end

  def get_dockets_slots(dockets)
    # fetching all the RO keys of the dockets
    regional_office_keys = dockets.map { |_date, docket| docket.regional_office_key }

    # fetching data of all dockets staff based on the regional office keys
    ro_staff_hash = HearingDayRepository.ro_staff_hash(regional_office_keys)

    # returns a hash of docket date (string) as key and number of slots for the docket
    # as they key
    dockets.map do |date, docket|
      record = ro_staff_hash[docket.regional_office_key]
      [date, (HearingDayRepository.slots_based_on_type(staff: record, type: docket.type, date: docket.date) if record)]
    end.to_h
  end

  class << self
    def repository
      JudgeRepository
    end

    def list_all
      Rails.cache.fetch("#{Rails.env}_list_of_judges_from_vacols") do
        repository.find_all_judges
      end
    end

    def list_all_with_name_and_id
      # idt requires full name and sattyid
      Rails.cache.fetch("#{Rails.env}_list_of_judges_from_vacols_with_name_and_id") do
        repository.find_all_judges_with_name_and_id
      end
    end
  end
end
