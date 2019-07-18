# frozen_string_literal: true

class HearingDayRange
  def initialize(start_date, end_date, regional_office = nil)
    @start_date = start_date
    @end_date = end_date
    @regional_office = regional_office
  end

  def load_days
    if regional_office.nil?
      HearingDay.where("DATE(scheduled_for) between ? and ?", start_date, end_date)
    elsif regional_office == HearingDay::REQUEST_TYPES[:central]
      HearingDay.where(
        "request_type = ? and DATE(scheduled_for) between ? and ?",
        HearingDay::REQUEST_TYPES[:central],
        start_date,
        end_date
      )
    else
      HearingDay.where(
        "regional_office = ? and DATE(scheduled_for) between ? and ?",
        regional_office,
        start_date,
        end_date
      )
    end
  end

  def list_upcoming_hearing_days(user)
    if user&.vso_employee?
      upcoming_days_for_vso_user(user)
    elsif user&.roles&.include?("Hearing Prep")
      upcoming_days_for_judge(user)
    else
      load_days
    end
  end

  def all_hearing_days_with_hearings_hash(current_user_id = nil)
    total_video_and_co = load_days
    vacols_hearings_for_days = HearingRepository.fetch_hearings_for_parents(total_video_and_co.pluck(:id))

    total_video_and_co
      .select { |hearing_day| !hearing_day.lock }
      .map do |hearing_day|
        all_hearings = (hearing_day.hearings || []) + (vacols_hearings_for_days[hearing_day.id.to_s] || [])
        scheduled_hearings = self.class.filter_non_scheduled_hearings(all_hearings || [])

        self.class.hearing_day_hash_with_hearings(hearing_day, scheduled_hearings, current_user_id)
      end
  end

  def open_hearing_days_with_hearings_hash(current_user_id = nil)
    all_hearing_days_with_hearings_hash(current_user_id).select do |hearing_day|
      self.class.open_hearing_day?(hearing_day)
    end
  end

  class << self
    def open_hearing_day?(hearing_day)
      hearing_day["hearings"].length < hearing_day["total_slots"]
    end

    def hearing_day_for_judge?(hearing_day, user)
      hearing_day.judge == user || hearing_day.hearings.any? { |hearing| hearing.judge == user }
    end

    def ama_hearing_day_for_vso_user?(hearing_day, user)
      hearing_day.hearings.any? { |hearing| hearing.assigned_to_vso?(user) }
    end

    def legacy_hearing_day_for_vso_user?(vacols_hearings, loaded_hearings, user)
      vacols_hearing&.any? do |hearing|
        loaded_hearings.find { |legacy_hearing| legacy_hearing.id == hearing.id }&.assigned_to_vso?(user)
      end
    end

    def filter_non_scheduled_hearings(hearings)
      hearings.select do |hearing|
        if hearing.is_a?(Hearing)
          !%w[postponed cancelled].include?(hearing.disposition)
        else
          hearing.vacols_record.hearing_disp != "P" && hearing.vacols_record.hearing_disp != "C"
        end
      end
    end

    def hearing_day_hash_with_hearings(hearing_day, scheduled_hearings, current_user_id)
      hearing_day.to_hash.merge(
        "hearings" => scheduled_hearings.map { |hearing| hearing.quick_to_hash(current_user_id) }
      )
    end
  end

  private

  attr_reader :start_date
  attr_reader :end_date
  attr_reader :regional_office

  def upcoming_days_for_judge(user)
    hearing_days_in_range = HearingDay.includes(:hearings)
      .where("DATE(scheduled_for) between ? and ?", start_date, end_date)
    vacols_hearings = HearingRepository.fetch_hearings_for_parents_assigned_to_judge(
      hearing_days_in_range.first(1000).pluck(:id), user
    )

    hearing_days_in_range.select do |hearing_day|
      self.class.hearing_day_for_judge?(hearing_day, user) || !vacols_hearings[hearing_day.id.to_s].nil?
    end
  end

  def upcoming_days_for_vso_user(user)
    days_in_range = hearing_days_in_range(start_date, end_date)

    ama_days = days_in_range.select do |hearing_day|
      self.class.ama_hearing_day_for_vso_user?(hearing_day, user)
    end

    remaining_days = days_in_range.where.not(id: ama_days.pluck(:id)).order(:scheduled_for).limit(1000)

    vacols_hearings_for_remaining_days = HearingRepository.fetch_hearings_for_parents(remaining_days.map(&:id))

    loaded_hearings = LegacyHearing
      .includes(appeal: [tasks: :assigned_to])
      .where(id: vacols_hearings_for_remaining_days.values.flatten.pluck(:id))

    vacols_days = remaining_days.select do |day|
      vacols_hearings = vacols_hearings_for_remaining_days[day.id.to_s]

      self.class.legacy_hearing_day_for_vso_user?(vacols_hearings, legacy_hearings, user)
    end

    ama_days + vacols_days
  end
end
