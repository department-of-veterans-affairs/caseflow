# frozen_string_literal: true

class Judge
  attr_reader :user
  def initialize(user)
    @user = user
  end

  def upcoming_dockets
    @upcoming_dockets ||= upcoming_hearings_grouped_by_date.transform_values do |hearings|
      HearingDocket.from_hearings(hearings)
    end

    # assign number of slots to its corresponding docket
    @upcoming_dockets.map do |date, hearing_docket|
      hearing_docket.slots = HearingDay::SLOTS_BY_TIMEZONE[HearingMapper
        .timezone(hearing_docket.regional_office_key)]
      [date, hearing_docket]
    end.to_h
  end

  def docket?(date)
    !upcoming_hearings_on(date).empty?
  end

  def upcoming_hearings_on(date, is_fetching_issues = false)
    upcoming_hearings(is_fetching_issues).select do |hearing|
      hearing.scheduled_for.between?(date.beginning_of_day, date.end_of_day) || hearing.scheduled_for.to_date == date
    end
  end

  def attorneys
    JudgeTeam.for_judge(user).try(:attorneys) || []
  end

  private

  def upcoming_hearings_grouped_by_date
    upcoming_hearings.group_by { |h| h.scheduled_for.strftime("%F") }
  end

  def upcoming_hearings(is_fetching_issues = false)
    HearingRepository.fetch_hearings_for_judge(user.css_id, is_fetching_issues).sort_by(&:scheduled_for) +
      Hearing.joins(:judge).where(users: { css_id: user.css_id }).sort_by(&:scheduled_for)
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
