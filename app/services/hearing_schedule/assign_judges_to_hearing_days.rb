# frozen_string_literal: true

require "business_time"
require "set"

class HearingSchedule::AssignJudgesToHearingDays
  attr_reader :judges, :video_co_hearing_days

  TB_ADDITIONAL_NA_DAYS = 3
  CO_ROOM_NUM = "2"
  DAYS_OF_SEPARATION = 3

  class HearingDaysNotAllocated < StandardError; end
  class NoJudgesProvided < StandardError; end

  def initialize(schedule_period)
    @video_co_hearing_days = []
    @judges = {}
    @schedule_period = schedule_period
    @algo_counter = 0

    fetch_judge_non_availabilities
    fetch_judge_details
    fetch_hearing_days_for_schedule_period
  end

  def match_hearing_days_to_judges
    @assigned_hearing_days = []
    @unassigned_hearing_days = @video_co_hearing_days.shuffle
    evenly_assign_judges_to_hearing_days
    assign_remaining_hearing_days
    verify_assignments
    @assigned_hearing_days.sort_by(&:scheduled_for_as_date)
  end

  private

  def evenly_assign_judges_to_hearing_days
    sorted_judges = judges_sorted_by_available_days

    judge_count = sorted_judges.length
    total_hearing_day_count = @unassigned_hearing_days.length
    max_days_per_judge = [(total_hearing_day_count.to_f / judge_count).floor, 1].max

    sorted_judges.each do |css_id|
      days_assigned = 0

      @unassigned_hearing_days.delete_if do |current_hearing_day|
        break if days_assigned >= max_days_per_judge

        if day_can_be_assigned?(current_hearing_day, css_id)
          @assigned_hearing_days.push(*assign_judge_to_hearing_day(current_hearing_day, css_id))
          days_assigned += 1
          next true
        end
      end
    end
  end

  def assign_remaining_hearing_days
    @unassigned_hearing_days.delete_if do |current_hearing_day|
      assigned = false

      judges_sorted_by_assigned_days.each do |css_id|
        next unless day_can_be_assigned?(current_hearing_day, css_id)

        @assigned_hearing_days.push(*assign_judge_to_hearing_day(current_hearing_day, css_id))
        assigned = true
        break
      end

      next true if assigned
    end
  end

  def judges_sorted_by_assigned_days
    days_by_judge = @assigned_hearing_days.reduce({}) do |acc, hearing_day|
      acc[hearing_day.judge.css_id] ||= 0
      acc[hearing_day.judge.css_id] += 1
      acc
    end

    days_by_judge.to_a.shuffle.sort_by { |e| e[1] }.map { |e| e[0] }
  end

  def day_can_be_assigned?(current_hearing_day, css_id)
    scheduled_for = current_hearing_day.scheduled_for_as_date
    judge_id = @judges[css_id][:staff_info].sattyid

    problems = @judges[css_id][:non_availabilities].include?(scheduled_for) ||
               hearing_day_already_assigned?(current_hearing_day.id) ||
               judge_already_assigned_on_date?(judge_id, scheduled_for) ||
               (current_hearing_day.central_office? && judge_already_assigned_to_co?(judge_id))

    !problems
  end

  def hearing_day_already_assigned?(id)
    @assigned_hearing_days.any? { |day| day.id == id }
  end

  def judge_already_assigned_on_date?(judge_id, date)
    @assigned_hearing_days.any? do |day|
      day.judge_id.to_s == judge_id.to_s && (day.scheduled_for_as_date - date).abs <= DAYS_OF_SEPARATION
    end
  end

  def judge_already_assigned_to_co?(judge_id)
    @assigned_hearing_days.any? do |day|
      day.request_type == HearingDay::REQUEST_TYPES[:central] && day.judge_id.to_s == judge_id.to_s
    end
  end

  def verify_assignments
    if @assigned_hearing_days.length != @video_co_hearing_days.length
      if @algo_counter >= 20
        dates = @unassigned_hearing_days.map(&:scheduled_for_as_date)
        fail HearingSchedule::Errors::CannotAssignJudges.new(
          "Hearing days on these dates couldn't be assigned #{dates}.",
          dates: dates
        )
      end
      @algo_counter += 1
      match_hearing_days_to_judges
    end
  end

  # It's expected that the judge validations have been run before
  # running the algorithm. This assumes that the judge information
  # already exists in VACOLS and in Caseflow database.
  def fetch_judge_details
    fail NoJudgesProvided if @judges.keys.empty?

    VACOLS::Staff.load_users_by_css_ids(@judges.keys).map do |judge|
      @judges[judge.sdomainid][:staff_info] = judge
    end
  end

  def judges_sorted_by_available_days
    @judges.sort_by { |_k, v| v[:non_availabilities].count }.to_h.keys.reverse
  end

  def co_hearing_days_by_date(date)
    @video_co_hearing_days
      .select(&:central_office?)
      .select { |day| day.scheduled_for_as_date == date }
  end

  def assign_judge_to_hearing_day(day, css_id)
    hearing_days = day.central_office? ? co_hearing_days_by_date(day.scheduled_for_as_date) : [day]

    hearing_days.map do |hearing_day|
      # Doing `.new` here instead of `.create` (or similar) to mimic
      # old behavior, and ensure backwards compatibility.
      hearing_day.judge = User.new(
        id: @judges[css_id][:staff_info].sattyid,
        full_name: get_judge_name(css_id),
        css_id: css_id
      )
      hearing_day
    end
  end

  def get_judge_name(css_id)
    staff_info = @judges[css_id][:staff_info]
    "#{staff_info.snamel}, #{staff_info.snamemi} #{staff_info.snamef}"
  end

  def fetch_judge_non_availabilities
    non_availabilities = @schedule_period.non_availabilities

    non_availabilities.each do |non_availability|
      next unless non_availability.instance_of? JudgeNonAvailability

      css_id = non_availability.object_identifier
      @judges[css_id] ||= {}
      @judges[css_id][:non_availabilities] ||= Set.new
      @judges[css_id][:non_availabilities] << non_availability.date if non_availability.date
    end
  end

  def fetch_hearing_days_for_schedule_period
    hearing_days = HearingDayRange.new(@schedule_period.start_date, @schedule_period.end_date).load_days
    @video_co_hearing_days = filter_co_hearings(hearing_days).freeze

    # raises an exception if hearing days have not already been allocated
    fail HearingDaysNotAllocated if @video_co_hearing_days.empty?

    travel_board_hearing_days = TravelBoardScheduleRepository.load_tb_days_for_range(@schedule_period.start_date,
                                                                                     @schedule_period.end_date)
    filter_travel_board_hearing_days(travel_board_hearing_days)
  end

  def valid_co_day?(day)
    day.central_office? && day.room == CO_ROOM_NUM
  end

  def filter_co_hearings(video_co_hearing_days)
    video_co_hearing_days.select do |hearing_day|
      (valid_co_day?(hearing_day) || !hearing_day.regional_office.nil?) && !hearing_day_already_assigned(hearing_day)
    end
  end

  def hearing_day_already_assigned(hearing_day)
    assigned = !hearing_day.judge_id.nil?

    if assigned
      @judges.each do |css_id, judge|
        if judge[:staff_info].sattyid == hearing_day.judge_id.to_s
          @judges[css_id][:non_availabilities] << hearing_day.scheduled_for_as_date
        end
      end
    end
    assigned
  end

  # Adds 3 days and 3 days prior non-available days for each Judge assigned to a travel board.
  def filter_travel_board_hearing_days(tb_hearing_days)
    tb_hearing_days_formatted = TravelBoardScheduleMapper.convert_from_vacols_format(tb_hearing_days)

    tb_hearing_days_formatted.each do |tb_record|
      # assign non-availability days to all the travel board judges
      tb_judge_ids = [tb_record[:tbmem_1], tb_record[:tbmem_2], tb_record[:tbmem_3], tb_record[:tbmem_4]].compact
      judges = @judges.select { |_key, judge| tb_judge_ids.include?(judge[:staff_info].sattyid) }

      judges.each_value do |judge_staff_info|
        css_id = judge_staff_info[:staff_info].sdomainid

        @judges[css_id][:non_availabilities] ||= Set.new
        @judges[css_id][:non_availabilities] +=
          (
            TB_ADDITIONAL_NA_DAYS.business_days
              .before(tb_record[:start_date])..TB_ADDITIONAL_NA_DAYS.business_days
              .after(tb_record[:end_date])
          ).reject(&:on_weekend?)
      end
    end
  end
end
