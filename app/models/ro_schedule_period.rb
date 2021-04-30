# frozen_string_literal: true

##
# RoSchedulePeriod represents a schedule period for bulk assigning hearing days.
# This record is created when user uploads a RO Assignment spreadsheet for a date range if it passes spreadsheet
# validation. Once created, it creates NonAvailibility records for ROs and CO which are used for generating
# the schedule. The generated hearing schedule is cached for 4 days. When user confirms the
# the schedule, HearingDay records are created.
##
class RoSchedulePeriod < SchedulePeriod
  validate :validate_spreadsheet, on: :create
  after_create :import_spreadsheet

  cache_attribute :algorithm_assignments, expires_in: 4.days do
    generate_ro_hearing_schedule
  end

  # Run various validations on the uploaded spreadsheet and record errors
  def validate_spreadsheet
    validate_spreadsheet = HearingSchedule::ValidateRoSpreadsheet.new(spreadsheet, start_date, end_date)
    errors[:base] << validate_spreadsheet.validate
  end

  # Create NonAvailibility records for ROs and CO and Allocation records for each RO
  def import_spreadsheet
    RoNonAvailability.import_ro_non_availability(self)
    CoNonAvailability.import_co_non_availability(self)
    Allocation.import_allocation(self)
  end

  # When user confirms the schedule, try to create hearing days
  def schedule_confirmed(hearing_schedule)
    RoSchedulePeriod.transaction do
      start_confirming_schedule
      begin
        transaction do
          HearingDay.create_schedule(hearing_schedule)
        end
        super
      rescue StandardError
        end_confirming_schedule
        raise ActiveRecord::Rollback
      end
      end_confirming_schedule
    end
  end

  private

  # Validate fields for each video hearing day
  def format_ro_hearing_data(ro_allocations)
    ro_allocations.reduce([]) do |acc, (ro_key, ro_info)|
      ro_info[:allocated_dates].each_value do |dates|
        dates.each do |date, rooms|
          rooms.each do |room|
            acc << HearingDayMapper.hearing_day_field_validations(
              request_type: (ro_key == "NVHQ") ? :virtual : :video,
              scheduled_for: Date.new(date.year, date.month, date.day),
              room: room[:room_num],
              regional_office: (ro_key == "NVHQ") ? nil : ro_key
            )
          end
        end
      end
      acc
    end
  end

  # Generate hearing days for ROs and CO based on non-availibility days and allocated days
  def generate_ro_hearing_schedule
    # Initialize the hearing day schedule
    generate_hearings_days = HearingSchedule::GenerateHearingDaysSchedule.new(self)

    # Distribute the requested days without the room constraint per RO
    hearing_days_without_room = format_ro_hearing_data(generate_hearings_days.allocate_no_room_hearing_days_to_ros)

    # Distribute the requested days adding the room constraint per RO
    # hearing_days_with_room = format_ro_hearing_data(generate_hearings_days.allocate_hearing_days_to_ros)

    # Distribute the available Central Office hearing days
    co_hearing_days = generate_hearings_days.generate_co_hearing_days_schedule

    # Combine the available hearing days
    hearing_days =  co_hearing_days + hearing_days_without_room
    hearing_days.sort_by { |day| day[:scheduled_for] }
  end
end
