# frozen_string_literal: true

##
# HearingDay groups hearings, both AMA and legacy, by a regional office and a room at the BVA.
# Hearing Admin can create a HearingDay either individually or in bulk at the begining of
# each year by uploading bunch of spreadsheets.
#
# Each HearingDay has a request type which applies to all hearings associated for that day.
# Request types:
#   'V' (also known as video hearing):
#       The veteran/appellant travels to a regional office to have a hearing through video conference
#       with a VLJ (Veterans Law Judge) who joins from the board at Washington D.C.
#   'C' (also known as Central):
#       The veteran/appellant travels to the board in D.C to have a in-person hearing with the VLJ.
#   'T' (also known as travel board)
#       The VLJ travels to the the Veteran/Appellant's closest regional office to conduct the hearing.
#
# If the request type is video('V'), then the HearingDay has a regional office associated.
# Currently, a video hearing can be switched to a virtual hearing represented by VirtualHearing.
#
# Each HearingDay has a maximum number of hearings that can be held which is either based on the
# timezone of associated regional office or 12 if the request type is central('C).
#
# A HearingDay can be assigned to a judge.

class HearingDay < CaseflowRecord
  include UpdatedByUserConcern

  acts_as_paranoid

  belongs_to :judge, class_name: "User"
  belongs_to :created_by, class_name: "User"
  has_many :hearings, -> { not_scheduled_in_error }

  class HearingDayHasChildrenRecords < StandardError; end

  REQUEST_TYPES = Constants::HEARING_REQUEST_TYPES.with_indifferent_access.freeze

  SLOTS_BY_REQUEST_TYPE = {
    REQUEST_TYPES[:central] => 10,
    REQUEST_TYPES[:virtual] => 8 # TBD. Dummy value for testing until we know more.
  }.freeze

  SLOTS_BY_TIMEZONE = {
    "America/New_York" => 12,
    "America/Chicago" => 12,
    "America/Indiana/Indianapolis" => 12,
    "America/Kentucky/Louisville" => 12,
    "America/Denver" => 12,
    "America/Phoenix" => 12,
    "America/Los_Angeles" => 12,
    "America/Boise" => 12,
    "America/Puerto_Rico" => 12,
    "Asia/Manila" => 12,
    "Pacific/Honolulu" => 12,
    "America/Anchorage" => 12
  }.freeze

  DEFAULT_SLOT_LENGTH = 60 # in minutes

  before_create :assign_created_by_user
  after_update :update_children_records

  # Validates if the judge id maps to an actual record.
  validates :judge, presence: true, if: -> { judge_id.present? }

  validates :regional_office, absence: true, if: :central_office_or_virtual?
  validates :regional_office,
            inclusion: {
              in: RegionalOffice.all.map(&:key),
              message: "key (%<value>s) is invalid"
            },
            unless: :central_office_or_virtual?

  validates :request_type,
            inclusion: {
              in: REQUEST_TYPES.values,
              message: "is invalid"
            }
  validates :first_slot_time,
            format: { with: /\A(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]\z/, message: "doesn't match hh:mm time format" },
            allow_nil: true

  def central_office?
    request_type == REQUEST_TYPES[:central]
  end

  def virtual?
    request_type == REQUEST_TYPES[:virtual]
  end

  def central_office_or_virtual?
    central_office? || virtual?
  end

  def scheduled_for_as_date
    scheduled_for.to_date
  end

  def confirm_no_children_records
    fail HearingDayHasChildrenRecords if !vacols_hearings.empty? || !hearings.empty?
  end

  def vacols_hearings
    HearingRepository.fetch_hearings_for_parent(id)
  end

  def open_hearings
    closed_hearing_dispositions = [
      Constants.HEARING_DISPOSITION_TYPES.postponed,
      Constants.HEARING_DISPOSITION_TYPES.cancelled,
      Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
    ]

    (hearings + vacols_hearings).reject { |hearing| closed_hearing_dispositions.include?(hearing.disposition) }
  end

  def hearings_for_user(current_user)
    caseflow_and_vacols_hearings = vacols_hearings + hearings

    if current_user.vso_employee?
      caseflow_and_vacols_hearings = caseflow_and_vacols_hearings.select do |hearing|
        hearing.assigned_to_vso?(current_user)
      end
    end

    if current_user.roles.include?("Hearing Prep")
      caseflow_and_vacols_hearings = caseflow_and_vacols_hearings.select do |hearing|
        hearing.assigned_to_judge?(current_user)
      end
    end

    caseflow_and_vacols_hearings
  end

  def to_hash
    video_hearing_days_request_types = if VirtualHearing::VALID_REQUEST_TYPES.include? request_type
                                         HearingDayRequestTypeQuery
                                           .new(HearingDay.where(id: id))
                                           .call
                                       else
                                         {}
                                       end

    ::HearingDaySerializer.new(
      self,
      params: { video_hearing_days_request_types: video_hearing_days_request_types }
    ).serializable_hash[:data][:attributes]
  end

  def hearing_day_full?
    lock || open_hearings.count >= total_slots
  end

  def total_slots
    # 04-19-2021 number_of_slots database column added
    return number_of_slots unless number_of_slots.nil?

    # If central or virtual return number based on request type
    return SLOTS_BY_REQUEST_TYPE[request_type] if central_office_or_virtual?

    # Return 12, all timezones are set to 12
    SLOTS_BY_TIMEZONE[RegionalOffice.find!(regional_office).timezone]
  end

  def slot_length_minutes
    # 04-19-2021 slot_length_minutes database column added
    return self[:slot_length_minutes] unless self[:slot_length_minutes].nil?

    DEFAULT_SLOT_LENGTH
  end

  # In order to display timeslots for the various regional_office we need to know
  # what time the first slot should be. This method returns that information as
  # a string representing an iso8601 formatted datetime
  #
  # Examples:
  # "2021-04-23T08:30:00-04:00"
  # "2021-04-23T09:00:00-04:00"
  # "2021-04-23T08:00:00-06:00"
  #
  # This may seem unnessecarily complex, when we could more simply send a time string like "08:30"
  # Sending a string like "08:30" does not end up being simpler in practice. It moves the work
  # of knowing/figuring out the timezone elsewhere (the front-end).
  #
  # The iso8601 strings come from a combination of these three pieces:
  # - Time: first_slot_time, or a default string like "09:00"
  #    - first_slot_time is ALWAYS in eastern time.
  # - Timezone: regional office's timezone property like "America/Los_Angeles"
  # - Date: from the scheduled_for column for this hearing_day
  def begins_at
    # If 'first_slot_time' column has a value, use that
    unless first_slot_time.nil?
      return combine_time_and_date(first_slot_time, "America/New_York", scheduled_for)
    end

    # if no value in db and central, 09:00
    return combine_time_and_date("09:00", "America/New_York", scheduled_for) if central_office?

    # if no value in db and virtual, 08:30
    return combine_time_and_date("08:30", "America/New_York", scheduled_for) if virtual?

    # if no value in db and video (not central or virtual): first_slot_time is 08:30
    combine_time_and_date("08:30", RegionalOffice.find!(regional_office).timezone, scheduled_for)
  end

  def judge_first_name
    judge ? judge.full_name.split(" ").first : nil
  end

  def judge_last_name
    judge ? judge.full_name.split(" ").last : nil
  end

  private

  def assign_created_by_user
    self.created_by ||= RequestStore[:current_user]
  end

  def update_children_records
    vacols_hearings.each do |hearing|
      hearing.update_caseflow_and_vacols(
        **only_changed(room: room, bva_poc: bva_poc, judge_id: judge&.id)
      )
    end

    hearings.each do |hearing|
      hearing.update!(
        **only_changed(room: room, bva_poc: bva_poc, judge_id: judge&.id)
      )
    end
  end

  def only_changed(possibles_hash)
    changed_hash = {}
    possibles_hash.each_key do |key|
      changed_hash[key] = possibles_hash[key] if saved_changes.key?(key)
    end

    changed_hash
  end

  # Creates a datetime with timezone from these parts
  # - Time, a string like "08:30"
  # - Timezone, a string like "America/Los_Angeles"
  # - Date, a ruby Date
  # :reek:UtilityFunction
  def combine_time_and_date(time, timezone, date)
    # Parse the time string into a ruby Time instance with zone
    time_with_zone = time.in_time_zone(timezone)
    # Make a string like "2021-04-23 08:30:00"
    time_and_date_string = "#{date.strftime('%F')} #{time_with_zone.strftime('%T')}"
    # Parse the combined string into a ruby DateTime
    combined_datetime = time_and_date_string.in_time_zone(timezone)
    # Format the DateTime to iso8601 like "2021-04-23T08:30:00-06:00"
    formatted_datetime_string = combined_datetime.iso8601

    formatted_datetime_string
  end

  class << self
    def create_schedule(scheduled_hearings)
      scheduled_hearings.each do |hearing_hash|
        HearingDay.create(hearing_hash)
      end
    end

    def update_schedule(updated_hearing_days)
      updated_hearing_days.each do |hearing_day|
        HearingDay.find(hearing_day.id).update!(
          judge: User.find_by_css_id_or_create_with_default_station_id(hearing_day.judge.css_id)
        )
      end
    end

    private

    def current_user_css_id
      RequestStore.store[:current_user].css_id.upcase
    end
  end
end
