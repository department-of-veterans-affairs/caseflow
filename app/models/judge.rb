class Judge
  JUDGE_STATION_ID = "101".freeze

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
    upcoming_hearings_on(date).count > 0
  end

  def upcoming_hearings_on(date)
    upcoming_hearings.select do |hearing|
      hearing.date.between?(date, date.end_of_day)
    end
  end

  private

  def upcoming_hearings_grouped_by_date
    upcoming_hearings.group_by { |h| h.date.strftime("%F") }
  end

  def upcoming_hearings
    Hearing.repository.upcoming_hearings_for_judge(user.css_id).sort_by(&:date)
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

    def create_from_vacols(staff_record)
      User.find_or_initialize_by(css_id: staff_record.sdomainid, station_id: JUDGE_STATION_ID).tap do |user|
        # Only update name in the DB if it is a new record,
        # We don't want to modify names on the existing records
        user.full_name = FullName.new(staff_record.snamef, staff_record.snamemi, staff_record.snamel)
          .formatted(:readable_full)
        user.save if user.new_record?
      end
    end
  end
end
