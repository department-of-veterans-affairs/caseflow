# Class to coordinate interactions between controller
# and repository class. Eventually may persist data to
# Caseflow DB. For now all schedule data is sent to the
# VACOLS DB (Aug 2018 implementation).
class HearingDay < ApplicationRecord
  HEARING_TYPES = {
    video: "V",
    travel: "T",
    central: "C"
  }.freeze

  CASEFLOW_SCHEDULE_DATE = Date.new(2019, 3, 31).freeze

  class << self
    def create_hearing_day(hearing_hash)
      hearing_date = hearing_hash[:hearing_date]
      hearing_date = hearing_date.is_a?(DateTime) ? hearing_date : Time.zone.parse(hearing_date).to_datetime
      if hearing_date > CASEFLOW_SCHEDULE_DATE
        hearing_hash = hearing_hash.merge(created_by: current_user_css_id, updated_by: current_user_css_id)
        create(hearing_hash).to_hash
      else
        HearingDayRepository.create_vacols_hearing!(hearing_hash)
      end
    end

    def update_hearing_day(hearing, hearing_hash)
      if hearing.is_a?(HearingDay)
        hearing_hash = hearing_hash.merge(updated_by: current_user_css_id)
        hearing.update(hearing_hash)
      else
        HearingDayRepository.update_vacols_hearing!(hearing, hearing_hash)
      end
    end

    def create_schedule(scheduled_hearings)
      scheduled_hearings.each do |hearing_hash|
        HearingDay.create_hearing_day(hearing_hash)
      end
    end

    def update_schedule(updated_hearings)
      updated_hearings.each do |hearing_hash|
        hearing_to_update = HearingDay.find_hearing_day(hearing_hash[:hearing_type], hearing_hash[:id])
        hearing_hash.delete(:hearing_key)
        HearingDay.update_hearing_day(hearing_to_update, hearing_hash)
      end
    end

    def load_days(start_date, end_date, regional_office = nil)
      if regional_office.nil?
        cf_video_and_co = where("DATE(hearing_date) between ? and ?", start_date, end_date).each_with_object([])
        video_and_co, travel_board = HearingDayRepository.load_days_for_range(start_date, end_date)
      elsif regional_office == HEARING_TYPES[:central]
        cf_video_and_co = []
        video_and_co, travel_board = HearingDayRepository.load_days_for_central_office(start_date, end_date)
      else
        cf_video_and_co = where("regional_office = ? and DATE(hearing_date) between ? and ?",
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
                     HearingRepository.fetch_co_hearings_for_parent(hearing_day[:hearing_date])
                   else
                     HearingRepository.fetch_video_hearings_for_parent(hearing_day[:id])
                   end

        scheduled_hearings = filter_non_scheduled_hearings(hearings)
        total_slots = HearingDayRepository
          .fetch_hearing_day_slots(regional_office_hash[hearing_day[:regional_office]], hearing_day)

        next unless scheduled_hearings.length < total_slots
        enriched_hearing_days << hearing_day.slice(:id, :hearing_date, :hearing_type, :room_info)
        enriched_hearing_days[enriched_hearing_days.length - 1][:total_slots] = total_slots
        enriched_hearing_days[enriched_hearing_days.length - 1][:hearings] = scheduled_hearings
      end
      enriched_hearing_days
    end

    def filter_non_scheduled_hearings(hearings)
      filtered_hearings = []
      hearings.each do |hearing|
        if hearing.vacols_record.hearing_type == HEARING_TYPES[:central]
          if !hearing.vacols_record.folder_nr.nil?
            filtered_hearings << hearing
          end
        elsif hearing.vacols_record.hearing_disp != "P" && hearing.vacols_record.hearing_disp != "C"
          filtered_hearings << hearing
        end
      end
      filtered_hearings
    end

    def find_hearing_day(hearing_type, hearing_key)
      find(hearing_key)
    rescue ActiveRecord::RecordNotFound
      HearingDayRepository.find_hearing_day(hearing_type, hearing_key)
    end

    private

    def enrich_with_judge_names(hearing_days)
      vlj_ids = []
      hearing_days_hash = []
      hearing_days.each do |hearing_day|
        hearing_days_hash << hearing_day.to_hash
        vlj_ids << hearing_day[:judge_id]
      end

      judges = User.css_ids_by_vlj_ids(vlj_ids)

      hearing_days_hash.each_with_object([]) do |hearing_day, result|
        judge_info = judges[hearing_day[:judge_id]]
        if !judge_info.nil?
          hearing_day = hearing_day.merge(judge_first_name: judge_info[:first_name],
                                          judge_last_name: judge_info[:last_name])
        end
        result << hearing_day
      end
    end

    def current_user_css_id
      RequestStore.store[:current_user].css_id.upcase
    end
  end

  def to_hash
    as_json.each_with_object({}) do |(k, v), result|
      result[k.to_sym] = v
    end
  end
end
