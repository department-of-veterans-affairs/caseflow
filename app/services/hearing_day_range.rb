# frozen_string_literal: true

class HearingDayRange
  include ActiveModel::Validations
  include Pagy::Backend

  validate :valid_regional_office_key, :valid_start_date, :valid_end_date
  attr_reader :start_date, :end_date, :regional_office, :user, :pagination, :query,
              :page

  def initialize(params)
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @regional_office = params[:regional_office]
    @user = params[:user]
    @query = params[:query]
    @page = params[:page] || 1
  end

  def hearing_days_for_user
    if return_all_upcoming_hearing_days?
      load_days
    elsif user&.vso_employee?
      upcoming_days_for_vso_user
    elsif user&.roles&.include?("Hearing Prep")
      upcoming_days_for_judge
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

  def open_hearing_days_with_hearings_hash
    # Optimzation: shared for every call to hash the HearingDay.
    video_hearing_days_request_types = HearingDayRequestTypeQuery.new.call

    all_hearing_days
      .map do |hearing_day, scheduled_hearings|
        hearing_day_serialized = ::HearingDaySerializer.new(
          hearing_day,
          params: { video_hearing_days_request_types: video_hearing_days_request_types }
        ).serializable_hash[:data][:attributes]

        hearing_day_serialized.merge(
          hearings: scheduled_hearings.map do |hearing|
            HearingForHearingDaySerializer.new(hearing).serializable_hash[:data][:attributes]
          end
        )
      end
  end

  class << self
    def open_hearing_day?(hearing_day, scheduled_hearings)
      scheduled_hearings.size < hearing_day.total_slots
    end

    def ama_hearing_day_for_vso_user?(hearing_day)
      hearing_day.hearings.any? { |hearing| hearing.assigned_to_vso?(user) }
    end

    def legacy_hearing_day_for_vso_user?(vacols_hearings, loaded_hearings)
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
          %w[postponed cancelled].exclude?(hearing.disposition)
        else
          [
            VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:postponed],
            VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:cancelled],
            VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:scheduled_in_error]
          ].exclude?(hearing.vacols_record.hearing_disp)
        end
      end
    end
  end

  private

  attr_accessor :hearing_days
  attr_writer :pagination
  attr_reader :show_all

  def load_days
    hearing_days_in_range = HearingDay.in_range(start_date, end_date)

    days = if regional_office.nil?
             hearing_days_in_range
           elsif [HearingDay::REQUEST_TYPES[:central], HearingDay::REQUEST_TYPES[:virtual]].include?(regional_office)
             hearing_days_in_range.where(
               request_type: regional_office,
               regional_office: nil
             )
           else
             hearing_days_in_range.where(regional_office: regional_office)
           end

    ransack = days.ransack(query)
    self.pagination, self.hearing_days = pagy(
      ransack.result.includes(:judge),
      page: page
    )

    hearing_days
  end

  def upcoming_days_for_judge
    hearing_days_in_range = HearingDay.in_range(start_date, end_date)

    vacols_hearings = HearingRepository.fetch_hearings_for_parents_assigned_to_judge(
      all_days.first(1000).pluck(:id), user
    )

    days = hearing_days_in_range.for_judge_schedule(user, vacols_hearings.keys)

    ransack = days.ransack(query)
    self.pagination, self.hearing_days = pagy(
      ransack.result.includes(:judge, hearings: [appeal: [tasks: :assigned_to]]),
      page: page
    )

    hearing_days
  end

  def upcoming_days_for_vso_user
    hearing_days_in_range = HearingDay
      .in_range(start_date, end_date)
      .includes(:judge, hearings: [appeal: [tasks: :assigned_to]])
    ama_days = ama_days_for_vso_user(day_range)

    remaining_days = hearing_days_in_range.where.not(id: ama_days.pluck(:id)).order(
      Arel.sql(
        "CASE WHEN regional_office = '#{user.regional_office}' THEN 1 ELSE 2 END, "\
        "scheduled_for"
      )
    ).limit(1000)

    vacols_hearings_for_remaining_days = HearingRepository.fetch_hearings_for_parents(remaining_days.map(&:id))

    loaded_hearings = LegacyHearing
      .includes(appeal: [tasks: :assigned_to])
      .where(id: vacols_hearings_for_remaining_days.values.flatten.pluck(:id))

    vacols_days = remaining_days.select do |day|
      vacols_hearings = vacols_hearings_for_remaining_days[day.id.to_s]

      self.class.legacy_hearing_day_for_vso_user?(vacols_hearings, loaded_hearings)
    end

    ama_days + vacols_days
  end

  def ama_days_for_vso_user(day_range)
    day_range.select do |hearing_day|
      self.class.ama_hearing_day_for_vso_user?(hearing_day)
    end
  end

  def return_all_upcoming_hearing_days?
    ActiveRecord::Type::Boolean.new.deserialize(show_all) &&
      user&.roles&.include?("Hearing Prep")
  end

  def valid_start_date
    if start_date.nil? || start_date.is_a?(String)
      errors.add(:start_date, "Start date is not valid.")
    end
  end

  def valid_end_date
    if end_date.nil? || end_date.is_a?(String)
      errors.add(:end_date, "End date is not valid.")
    end
  end

  def valid_regional_office_key
    begin
      HearingDayMapper.validate_regional_office(regional_office)
    rescue HearingDayMapper::InvalidRegionalOfficeError
      errors.add(:regional_office, "Selected regional office is invalid.")
    end
  end
end
