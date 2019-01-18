# Class to coordinate interactions between controller
# and repository class. Eventually may persist data to
# Caseflow DB. For now all schedule data is sent to the
# VACOLS DB (Aug 2018 implementation).
class HearingDay < ApplicationRecord
  acts_as_paranoid
  belongs_to :judge, class_name: "User"
  has_many :hearings
  validates :regional_office, absence: true, if: :central_office?

  REQUEST_TYPES = {
    video: "V",
    travel: "T",
    central: "C"
  }.freeze

  # rubocop:disable Style/SymbolProc
  after_update { |hearing_day| hearing_day.update_children_records }
  # rubocop:enable Style/SymbolProc

  def central_office?
    request_type == REQUEST_TYPES[:central]
  end

  def update_children_records
    hearings = if request_type == REQUEST_TYPES[:central]
                 HearingRepository.fetch_co_hearings_for_date(scheduled_for)
               else
                 HearingRepository.fetch_video_hearings_for_parent(id)
               end

    hearings.each do |hearing|
      hearing.update_caseflow_and_vacols(
        room: room,
        bva_poc: bva_poc,
        judge_id: judge ? judge.vacols_attorney_id : nil
      )
    end
  end

  def to_hash
    as_json.each_with_object({}) do |(k, v), result|
      result[k.to_sym] = v
    end.merge(judge_first_name: judge ? judge.full_name.split(" ").first : nil,
              judge_last_name: judge ? judge.full_name.split(" ").last : nil)
  end

  # These dates indicate the date in which we pull parent records into Caseflow. For
  # legacy appeals, the children hearings will continue to be stored in VACOLS.
  CASEFLOW_V_PARENT_DATE = Date.new(2019, 3, 31).freeze
  CASEFLOW_CO_PARENT_DATE = Date.new(2018, 12, 31).freeze

  class << self
    def to_hash(hearing_day)
      if hearing_day.is_a?(HearingDay)
        hearing_day.to_hash
      else
        HearingDayRepository.to_hash(hearing_day)
      end
    end

    def array_to_hash(hearing_days)
      hearing_days.map do |hearing_day|
        HearingDay.to_hash(hearing_day)
      end
    end

    def create_hearing_day(hearing_hash)
      scheduled_for = hearing_hash[:scheduled_for]
      scheduled_for = if scheduled_for.is_a?(DateTime) | scheduled_for.is_a?(Date)
                        scheduled_for
                      else
                        Time.zone.parse(scheduled_for).to_datetime
                      end
      comparison_date = (hearing_hash[:request_type] == "C") ? CASEFLOW_CO_PARENT_DATE : CASEFLOW_V_PARENT_DATE
      if scheduled_for > comparison_date
        hearing_hash = hearing_hash.merge(created_by: current_user_css_id, updated_by: current_user_css_id)
        create(hearing_hash).to_hash
      else
        HearingDayRepository.create_vacols_hearing!(hearing_hash)
      end
    end

    def create_schedule(scheduled_hearings)
      scheduled_hearings.each do |hearing_hash|
        HearingDay.create_hearing_day(hearing_hash)
      end
    end

    def update_schedule(updated_hearings)
      updated_hearings.each do |hearing_hash|
        hearing_to_update = HearingDay.find(hearing_hash[:id])
        hearing_to_update.update!(judge: User.find_by_css_id_or_create_with_default_station_id(hearing_hash[:css_id]))
      end
    end

    def load_days(start_date, end_date, regional_office = nil)
      if regional_office.nil?
        cf_video_and_co = where("DATE(scheduled_for) between ? and ?", start_date, end_date)
        video_and_co, travel_board = HearingDayRepository.load_days_for_range(start_date, end_date)
      elsif regional_office == REQUEST_TYPES[:central]
        cf_video_and_co = where("request_type = ? and DATE(scheduled_for) between ? and ?",
                                "C", start_date, end_date)
        video_and_co, travel_board = HearingDayRepository.load_days_for_central_office(start_date, end_date)
      else
        cf_video_and_co = where("regional_office = ? and DATE(scheduled_for) between ? and ?",
                                regional_office, start_date, end_date)
        video_and_co, travel_board =
          HearingDayRepository.load_days_for_regional_office(regional_office, start_date, end_date)
      end

      {
        caseflow_hearings: cf_video_and_co,
        vacols_hearings: video_and_co,
        travel_board_hearings: travel_board
      }
    end

    def hearing_days_with_hearings_hash(start_date, end_date, regional_office = nil, current_user_id = nil)
      hearing_days = load_days(start_date, end_date, regional_office)
      total_video_and_co = hearing_days[:caseflow_hearings] + hearing_days[:vacols_hearings]

      # fetching all the RO keys of the dockets
      regional_office_keys = total_video_and_co.map(&:regional_office)
      regional_office_hash = HearingDayRepository.ro_staff_hash(regional_office_keys)

      hearing_days_to_array_of_days_and_hearings(
        total_video_and_co, regional_office.nil? || regional_office == "C"
      ).map do |value|
        scheduled_hearings = filter_non_scheduled_hearings(value[:hearings] || [])

        total_slots = HearingDayRepository.fetch_hearing_day_slots(
          regional_office_hash[value[:hearing_day].regional_office], value[:hearing_day]
        )

        if scheduled_hearings.length >= total_slots || value[:hearing_day][:lock]
          nil
        else
          HearingDay.to_hash(value[:hearing_day]).slice(:id, :scheduled_for, :request_type, :room).tap do |day|
            day[:hearings] = scheduled_hearings.map { |hearing| hearing.to_hash(current_user_id) }
            day[:total_slots] = total_slots
          end
        end
      end.compact
    end

    def filter_non_scheduled_hearings(hearings)
      hearings.select do |hearing|
        if hearing.is_a?(Hearing)
          true
        elsif hearing.request_type == REQUEST_TYPES[:central]
          !hearing.vacols_record.folder_nr.nil?
        else
          hearing.vacols_record.hearing_disp != "P" && hearing.vacols_record.hearing_disp != "C"
        end
      end
    end

    def find_hearing_day(request_type, hearing_key)
      find(hearing_key)
    rescue ActiveRecord::RecordNotFound
      HearingDayRepository.find_hearing_day(request_type, hearing_key)
    end

    private

    def hearing_days_to_array_of_days_and_hearings(total_video_and_co, is_video_hearing)
      # We need to associate all of the hearing days from postgres with all of the
      # hearings from VACOLS. For efficiency we make one call to VACOLS and then
      # create a hash of the results using either their ids or hearing dates as keys
      # depending on if it's a video or CO hearing.
      symbol_to_group_by = nil

      vacols_hearings_for_days = if is_video_hearing
                                   symbol_to_group_by = :scheduled_for

                                   HearingRepository.fetch_co_hearings_for_dates(
                                     total_video_and_co.map { |hearing_day| hearing_day[symbol_to_group_by] }
                                   )
                                 else
                                   symbol_to_group_by = :id

                                   HearingRepository.fetch_video_hearings_for_parents(
                                     total_video_and_co.map { |hearing_day| hearing_day[symbol_to_group_by] }
                                   )
                                 end

      # Group the hearing days with the same keys as the hearings
      grouped_hearing_days = total_video_and_co.group_by do |hearing_day|
        hearing_day[symbol_to_group_by].to_s
      end

      grouped_hearing_days.map do |key, day|
        hearings = (vacols_hearings_for_days[key] || []) + (day[0].is_a?(HearingDay) ? day[0].hearings : [])

        # There should only be one day, so we take the first value in our day array
        { hearing_day: day[0], hearings: hearings }
      end
    end

    def current_user_css_id
      RequestStore.store[:current_user].css_id.upcase
    end
  end
end
