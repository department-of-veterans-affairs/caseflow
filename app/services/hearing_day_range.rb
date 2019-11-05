# frozen_string_literal: true

class HearingDayRange
  include ActiveModel::Validations
  validate :regional_office_key_is_valid

  attr_reader :start_date
  attr_reader :end_date
  attr_reader :regional_office

  def initialize(start_date, end_date, regional_office = nil)
    @start_date = validate_start_date(start_date)
    @end_date = validate_end_date(end_date)
    @regional_office = regional_office
  end

  def load_days
    query = if regional_office.nil?
              HearingDay.where(
                "DATE(scheduled_for) between ? and ?", start_date, end_date
              )
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

    query.includes(:judge)
  end

  def upcoming_days_for_judge(user)
    days_in_range = hearing_days_in_range
    vacols_hearings = HearingRepository.fetch_hearings_for_parents_assigned_to_judge(
      days_in_range.first(1000).pluck(:id), user
    )

    days_in_range.select do |hearing_day|
      self.class.hearing_day_for_judge?(hearing_day, user) || !vacols_hearings[hearing_day.id.to_s].nil?
    end
  end

  def upcoming_days_for_vso_user(user)
    days_in_range = hearing_days_in_range

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

      self.class.legacy_hearing_day_for_vso_user?(vacols_hearings, loaded_hearings, user)
    end

    ama_days + vacols_days
  end

  def load_days_for_user(user)
    if user&.vso_employee?
      upcoming_days_for_vso_user(user)
    elsif user&.roles&.include?("Hearing Prep")
      upcoming_days_for_judge(user)
    else
      load_days
    end
  end

  def all_hearing_days
    total_video_and_co = load_days
    vacols_hearings_for_days = HearingRepository.fetch_hearings_for_parents(total_video_and_co.pluck(:id))

    total_video_and_co
      .reject(&:lock)
      .map do |hearing_day|
        all_hearings = (hearing_day.hearings || []) + (vacols_hearings_for_days[hearing_day.id.to_s] || [])
        scheduled_hearings = self.class.filter_non_scheduled_hearings(all_hearings || [])

        [hearing_day, scheduled_hearings]
      end
  end

  def open_hearing_days_with_hearings_hash(current_user_id = nil)
    all_hearing_days
      .select { |hearing_day, scheduled_hearings| self.class.open_hearing_day?(hearing_day, scheduled_hearings) }
      .map do |hearing_day, scheduled_hearings|
        self.class.hearing_day_hash_with_hearings(hearing_day, scheduled_hearings, current_user_id)
      end
  end

  class << self
    def open_hearing_day?(hearing_day, scheduled_hearings)
      scheduled_hearings.size < hearing_day.total_slots
    end

    def hearing_day_for_judge?(hearing_day, user)
      hearing_day.judge == user || hearing_day.hearings.any? { |hearing| hearing.judge == user }
    end

    def ama_hearing_day_for_vso_user?(hearing_day, user)
      hearing_day.hearings.any? { |hearing| hearing.assigned_to_vso?(user) }
    end

    def legacy_hearing_day_for_vso_user?(vacols_hearings, loaded_hearings, user)
      loaded_hearing_ids = loaded_hearings.map(&:id)
      vacols_hearings
        &.map do |hearing|
          idx = loaded_hearing_ids.find_index(hearing.id)

          if idx.nil?
            nil
          else
            loaded_hearings[idx]
          end
        end
        &.map { |hearing| hearing&.assigned_to_vso?(user) }
        &.any?
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
        hearings: scheduled_hearings.map { |hearing| hearing.quick_to_hash(current_user_id) }
      )
    end
  end

  private

  def validate_start_date(date)
    date.nil? ? (Time.zone.today.beginning_of_day - 30.days) : Date.parse(date)
  end

  def validate_end_date(date)
    date.nil? ? (Time.zone.today.beginning_of_day + 365.days) : Date.parse(date)
  end

  def regional_office_key_is_valid
    begin
      HearingDayMapper.validate_regional_office(regional_office)
    rescue HearingDayMapper::InvalidRegionalOfficeError
      errors.add(:regional_office, "Selected regional office is invalid.")
    end
  end

  def hearing_days_in_range
    HearingDay.includes(:judge, hearings: [appeal: [tasks: :assigned_to]])
      .where("DATE(scheduled_for) between ? and ?", start_date, end_date)
  end
end
