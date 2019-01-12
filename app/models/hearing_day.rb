# Class to coordinate interactions between controller
# and repository class. Eventually may persist data to
# Caseflow DB. For now all schedule data is sent to the
# VACOLS DB (Aug 2018 implementation).
class HearingDay < ApplicationRecord
  acts_as_paranoid
  belongs_to :judge, class_name: "User"
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
                 HearingRepository.fetch_co_hearings_for_parent(scheduled_for)
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
        cf_video_and_co = where("DATE(scheduled_for) between ? and ?", start_date, end_date).each_with_object([])
        video_and_co, travel_board = HearingDayRepository.load_days_for_range(start_date, end_date)
      elsif regional_office == REQUEST_TYPES[:central]
        cf_video_and_co = where("request_type = ? and DATE(scheduled_for) between ? and ?",
                                "C", start_date, end_date).each_with_object([])
        video_and_co, travel_board = HearingDayRepository.load_days_for_central_office(start_date, end_date)
      else
        cf_video_and_co = where("regional_office = ? and DATE(scheduled_for) between ? and ?",
                                regional_office, start_date, end_date).each_with_object([])
        video_and_co, travel_board =
          HearingDayRepository.load_days_for_regional_office(regional_office, start_date, end_date)
      end
      cf_video_and_co = enrich_with_judge_names(cf_video_and_co)
      total_video_and_co = video_and_co + cf_video_and_co
      [total_video_and_co, travel_board]
    end

    def load_days_with_open_hearing_slots(start_date, end_date, regional_office = nil)
      total_video_and_co, _travel_board = load_days(start_date, end_date, regional_office)

      # fetching all the RO keys of the dockets
      regional_office_keys = total_video_and_co.map { |hearing_day| hearing_day[:regional_office] }
      regional_office_hash = HearingDayRepository.ro_staff_hash(regional_office_keys)

      enriched_hearing_days = []
      total_video_and_co.each do |hearing_day|
        hearings = if hearing_day[:regional_office].nil?
                     HearingRepository.fetch_co_hearings_for_parent(hearing_day[:scheduled_for])
                   else
                     HearingRepository.fetch_video_hearings_for_parent(hearing_day[:id])
                   end

        scheduled_hearings = filter_non_scheduled_hearings(hearings)
        total_slots = HearingDayRepository
          .fetch_hearing_day_slots(regional_office_hash[hearing_day[:regional_office]], hearing_day)

        next unless scheduled_hearings.length < total_slots && !hearing_day[:lock]

        enriched_hearing_days << hearing_day.slice(:id, :scheduled_for, :request_type, :room)
        enriched_hearing_days[enriched_hearing_days.length - 1][:total_slots] = total_slots
        enriched_hearing_days[enriched_hearing_days.length - 1][:hearings] = scheduled_hearings
      end
      enriched_hearing_days
    end

    def filter_non_scheduled_hearings(hearings)
      filtered_hearings = []
      hearings.each do |hearing|
        if hearing.vacols_record.hearing_type == REQUEST_TYPES[:central]
          if !hearing.vacols_record.folder_nr.nil?
            filtered_hearings << hearing
          end
        elsif hearing.vacols_record.hearing_disp != "P" && hearing.vacols_record.hearing_disp != "C"
          filtered_hearings << hearing
        end
      end
      filtered_hearings
    end

    def find_hearing_day(request_type, hearing_key)
      find(hearing_key)
    rescue ActiveRecord::RecordNotFound
      HearingDayRepository.find_hearing_day(request_type, hearing_key)
    end

    private

    def enrich_with_judge_names(hearing_days)
      hearing_days_hash = []
      hearing_days.each do |hearing_day|
        hearing_days_hash << hearing_day.to_hash
      end
      hearing_days_hash
    end

    def current_user_css_id
      RequestStore.store[:current_user].css_id.upcase
    end
  end
end
