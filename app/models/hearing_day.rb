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
  has_one :vacols_user, through: :judge
  has_many :hearings, -> { not_scheduled_in_error }

  class HearingDayHasChildrenRecords < StandardError; end

  # Create a RegEx for the valid hearing time strings
  HEARING_TIME_STRING_PATTERN = /\A(0?[0-9]|1[0-9]|2[0-3]):[0-5][0-9]\z/.freeze

  REQUEST_TYPES = Constants::HEARING_REQUEST_TYPES.with_indifferent_access.freeze

  SLOTS_BY_REQUEST_TYPE = {
    REQUEST_TYPES[:virtual] => { default: 8, maximum: 12 },
    REQUEST_TYPES[:central] => { default: 10, maximum: 10 },
    REQUEST_TYPES[:video] => { default: 10, maximum: 10 },
    REQUEST_TYPES[:travel] => { default: 10, maximum: 10 }
  }.freeze

  DEFAULT_SLOT_LENGTH = 60 # in minutes
  VIRTUAL_HEARINGS_COUNT_STATEMENT = <<-SQL
    count(
      case when virtual_hearings.request_cancelled = false
        then true
      end
    ) as virtual_hearings_count
  SQL

  AVAILABLE_FILTERS = [
    :with_judges,
    :with_request_type
  ].freeze

  before_create :assign_created_by_user
  after_update :update_children_records

  # Validates if the judge id maps to an actual record.
  validates :judge, presence: true, if: -> { judge_id.present? }

  validates :regional_office, absence: true, if: :central_office?
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
            format: { with: HEARING_TIME_STRING_PATTERN, message: "doesn't match hh:mm time format" },
            allow_nil: true

  scope :in_range, lambda { |start_date, end_date|
    where("DATE(scheduled_for) between ? and ?", start_date, end_date)
  }

  scope :for_judge_schedule, lambda { |judge, vacols_ids|
    where(hearings: { judge_id: judge.id })
      .or(where(judge_id: judge.id))
      .or(where(id: vacols_ids))
      .includes(:hearings, :judge).distinct
  }

  scope :with_judges, lambda { |judges_ids|
    where(hearings: { judge_id: judges_ids })
      .or(where(judge_id: judges_ids))
      .includes(:hearings, :judge).distinct
  }

  scope :with_request_type, lambda { |request_types|

  }

  filterrific(
    available_filters: AVAILABLE_FILTERS
  )

  def self.counts_for_ama_hearings
    where(request_type: VirtualHearing::VALID_REQUEST_TYPES)
      .joins("INNER JOIN hearings ON hearing_days.id = hearings.hearing_day_id")
      .joins(<<-SQL)
        LEFT OUTER JOIN virtual_hearings
        ON virtual_hearings.hearing_id = hearings.id
        AND virtual_hearings.hearing_type = 'Hearing'
        AND virtual_hearings.request_cancelled = false
      SQL
      .group(:id)
      .select(
        "id",
        "request_type",
        VIRTUAL_HEARINGS_COUNT_STATEMENT,
        "count(hearings.id) as hearings_count"
      )
  end

  def self.counts_for_legacy_hearings
    where(request_type: VirtualHearing::VALID_REQUEST_TYPES)
      .joins("INNER JOIN legacy_hearings ON hearing_days.id = legacy_hearings.hearing_day_id")
      .joins(<<-SQL)
        LEFT OUTER JOIN virtual_hearings
        ON virtual_hearings.hearing_id = legacy_hearings.id
        AND virtual_hearings.hearing_type = 'LegacyHearing'
        AND virtual_hearings.request_cancelled = false
      SQL
      .group(:id)
      .select(
        "id",
        "request_type",
        VIRTUAL_HEARINGS_COUNT_STATEMENT,
        "count(legacy_hearings.id) as hearings_count"
      )
  end

  def self.ama_hearings_count_per_day
    Hearing.where(hearing_day_id: pluck(:id)).where(
      "disposition NOT in (?) or disposition is null",
      Hearing::CLOSED_HEARING_DISPOSITIONS
    ).group(:hearing_day_id).count
  end

  def self.legacy_hearings_count_per_day
    vacols_ids = LegacyHearing.where(hearing_day_id: pluck(:id)).pluck(:vacols_id)

    vacols_ids.in_groups_of(1000, false).reduce({}) do |acc, vacols_batched_ids|
      acc.merge(
        VACOLS::CaseHearing.where(hearing_pkseq: vacols_batched_ids)
         .where("hearing_disp NOT in (?) or hearing_disp is null", VACOLS::CaseHearing::CLOSED_HEARING_DISPOSITIONS)
         .group(:vdkey)
         .count
      )
    end
  end

  # This method returns the filter headers used on the table in the front-end for
  # hearings schedule.
  def self.filter_options(docket_queries)
    {
      readable_request_type: request_type_filters(docket_queries[:video_hearing_days_request_types]),
      regional_office: regional_office_filters,
      vlj: judge_filters(docket_queries[:judge_names])
    }
  end

  def self.request_type_filters(hearing_day_request_query)
    all.each_with_object({}) do |day, hash|
      request_type = HearingDaySerializer.get_readable_request_type(
        day,
        video_hearing_days_request_types: hearing_day_request_query
      ).split(",").first.strip

      if hash[request_type].present?
        hash[request_type][:count] += 1
      else
        hash[request_type] = {
          query_value: request_type,
          count: 1
        }
      end
    end
  end

  def self.regional_office_filters
    regional_offices_filters = all.each_with_object({}) do |day, hash|
      regional_office = HearingDayMapper.city_for_regional_office(day.regional_office)

      if hash[regional_office&.strip].present?
        hash[regional_office&.strip][:count] += 1
      else
        hash[regional_office&.strip] = {
          query_value: day.regional_office,
          count: 1
        }
      end
    end

    regional_offices_filters["Blank"] = regional_offices_filters.delete(nil)

    regional_offices_filters
  end

  def self.judge_filters(hearing_day_judge_name_query)
    judge_filters = all.includes(:judge).each_with_object({}) do |day, hash|
      judge_first_name = day.judge_first_name(hearing_day_judge_name_query)
      judge_last_name = day.judge_last_name(hearing_day_judge_name_query)
      judge_full_name = FullName.new(
        judge_first_name,
        nil,
        judge_last_name
      ).formatted(:form)

      if hash[judge_full_name].present?
        hash[judge_full_name][:count] += 1
      else
        hash[judge_full_name] = {
          query_value: day.judge_id || judge_full_name,
          count: 1
        }
      end
    end

    judge_filters["Blank"] = judge_filters.delete("")

    judge_filters
  end

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

  def ama_and_legacy_hearings
    hearings + vacols_hearings
  end

  def open_hearings
    ama_and_legacy_hearings.reject do |hearing|
      Hearing::CLOSED_HEARING_DISPOSITIONS.include?(hearing.disposition)
    end
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
    judge_names = HearingDayJudgeNameQuery.new(self.class.where(id: id)).call
    video_hearing_days_request_types = if VirtualHearing::VALID_REQUEST_TYPES.include? request_type
                                         HearingDayRequestTypeQuery
                                           .new(HearingDay.where(id: id))
                                           .call
                                       else
                                         {}
                                       end

    ::HearingDaySerializer.new(
      self,
      params: {
        video_hearing_days_request_types: video_hearing_days_request_types,
        judge_names: judge_names
      }
    ).serializable_hash[:data][:attributes]
  end

  def hearing_day_full?
    lock || open_hearings.count >= total_slots
  end

  def total_slots
    # Check if we have a stored value
    return number_of_slots unless number_of_slots.nil?

    SLOTS_BY_REQUEST_TYPE[request_type][:default]
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
    if first_slot_time.present?
      combine_time_and_date(first_slot_time, "America/New_York", scheduled_for)
    end
  end

  def judge_first_name(params = {})
    if params.present?
      params.dig(id, :first_name) || ""
    else
      judge ? judge.full_name.split(" ").first : nil
    end
  end

  def judge_last_name(params = {})
    if params[:judge_names].present?
      params[:judge_names].dig(id, :last_name) || ""
    else
      judge ? judge.full_name.split(" ").last : nil
    end
  end

  def judge_css_id
    judge&.css_id
  end

  def half_day?
    total_slots ? total_slots <= 5 : false
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
