# frozen_string_literal: true

# Class to coordinate interactions between controller
# and repository class. Eventually may persist data to
# Caseflow DB. For now all schedule data is sent to the
# VACOLS DB (Aug 2018 implementation).
class HearingDay < ApplicationRecord
  acts_as_paranoid
  belongs_to :judge, class_name: "User"
  has_many :hearings
  validates :regional_office, absence: true, if: :central_office?

  class HearingDayHasChildrenRecords < StandardError; end

  REQUEST_TYPES = {
    video: "V",
    travel: "T",
    central: "C"
  }.freeze

  SLOTS_BY_REQUEST_TYPE = { REQUEST_TYPES[:central] => 12 }.freeze

  SLOTS_BY_TIMEZONE = {
    "America/New_York" => 12,
    "America/Chicago" => 10,
    "America/Indiana/Indianapolis" => 12,
    "America/Kentucky/Louisville" => 12,
    "America/Denver" => 10,
    "America/Los_Angeles" => 8,
    "America/Boise" => 10,
    "America/Puerto_Rico" => 12,
    "Asia/Manila" => 8,
    "Pacific/Honolulu" => 8,
    "America/Anchorage" => 8
  }.freeze

  after_update :update_children_records

  def central_office?
    request_type == REQUEST_TYPES[:central]
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
      Constants.HEARING_DISPOSITION_TYPES.cancelled
    ]

    (hearings + vacols_hearings).reject { |hearing| closed_hearing_dispositions.include?(hearing.disposition) }
  end

  def to_hash
    as_json.each_with_object({}) do |(k, v), result|
      result[k.to_sym] = v
    end.merge(judge_first_name: judge ? judge.full_name.split(" ").first : nil,
              judge_last_name: judge ? judge.full_name.split(" ").last : nil)
  end

  def hearing_day_full?
    lock || open_hearings.count >= total_slots
  end

  def total_slots
    if request_type == REQUEST_TYPES[:central]
      return SLOTS_BY_REQUEST_TYPE[request_type]
    end

    SLOTS_BY_TIMEZONE[HearingMapper.timezone(regional_office)]
  end

  private

  def update_children_records
    vacols_hearings.each do |hearing|
      hearing.update_caseflow_and_vacols(
        **only_changed(room: room, bva_poc: bva_poc, judge_id: judge&.vacols_attorney_id)
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
      hearing_hash = hearing_hash.merge(created_by: current_user_css_id, updated_by: current_user_css_id)
      create(hearing_hash).to_hash
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

    def upcoming_days_for_judge(start_date, end_date, user)
      hearing_days_in_range = HearingDay.includes(:hearings)
        .where("DATE(scheduled_for) between ? and ?", start_date, end_date)
      vacols_hearings = HearingRepository.fetch_hearings_for_parents_assigned_to_judge(
        hearing_days_in_range.first(1000).pluck(:id), user
      )

      hearing_days_in_range.select do |hearing_day|
        hearing_day.judge == user ||
          hearing_day.hearings.any? { |hearing| hearing.judge == user } ||
          !vacols_hearings[hearing_day.id.to_s].nil?
      end
    end

    # rubocop:disable Metrics/AbcSize
    def upcoming_days_for_vso_user(start_date, end_date, user)
      hearing_days_with_ama_hearings = HearingDay.includes(hearings: [appeal: [tasks: :assigned_to]])
        .where("DATE(scheduled_for) between ? and ?", start_date, end_date).select do |hearing_day|
        hearing_day.hearings.any? { |hearing| hearing.assigned_to_vso?(user) }
      end

      remaining_hearing_days = HearingDay.where("DATE(scheduled_for) between ? and ?", start_date, end_date)
        .where.not(id: hearing_days_with_ama_hearings.pluck(:id)).order(:scheduled_for).limit(1000)

      vacols_hearings_for_remaining_hearing_days = HearingRepository.fetch_hearings_for_parents(
        remaining_hearing_days.pluck(:id)
      )

      caseflow_hearing_ids = vacols_hearings_for_remaining_hearing_days.values.flatten.pluck(:id)

      loaded_caseflow_hearings = LegacyHearing.includes(appeal: [tasks: :assigned_to]).where(id: caseflow_hearing_ids)

      hearing_days_with_vacols_hearings = remaining_hearing_days.select do |hearing_day|
        !vacols_hearings_for_remaining_hearing_days[hearing_day.id.to_s].nil? &&
          vacols_hearings_for_remaining_hearing_days[hearing_day.id.to_s].any? do |hearing|
            loaded_caseflow_hearings.detect { |legacy_hearing| legacy_hearing.id == hearing.id }.assigned_to_vso?(user)
          end
      end

      hearing_days_with_ama_hearings + hearing_days_with_vacols_hearings
    end
    # rubocop:enable Metrics/AbcSize

    def load_days(start_date, end_date, regional_office = nil)
      if regional_office.nil?
        where("DATE(scheduled_for) between ? and ?", start_date, end_date) +
          HearingDayRepository.load_video_days_for_range(start_date, end_date)
      elsif regional_office == REQUEST_TYPES[:central]
        where("request_type = ? and DATE(scheduled_for) between ? and ?", REQUEST_TYPES[:central], start_date, end_date)
      else
        where("regional_office = ? and DATE(scheduled_for) between ? and ?", regional_office, start_date, end_date) +
          HearingDayRepository.load_video_days_for_regional_office(regional_office, start_date, end_date)
      end
    end

    def list_upcoming_hearing_days(start_date, end_date, user, regional_office = nil)
      if user&.vso_employee?
        upcoming_days_for_vso_user(start_date, end_date, user)
      elsif user&.can?("Hearing Prep")
        upcoming_days_for_judge(start_date, end_date, user)
      else
        load_days(start_date, end_date, regional_office)
      end
    end

    def open_hearing_days_with_hearings_hash(start_date, end_date, regional_office = nil, current_user_id = nil)
      total_video_and_co = load_days(start_date, end_date, regional_office)

      # fetching all the RO keys of the dockets

      hearing_days_to_array_of_days_and_hearings(
        total_video_and_co, regional_office.nil? || regional_office == "C"
      ).map do |value|
        scheduled_hearings = filter_non_scheduled_hearings(value[:hearings] || [])

        total_slots = HearingDayRepository.fetch_hearing_day_slots(regional_office)

        if scheduled_hearings.length >= total_slots || value[:hearing_day][:lock]
          nil
        else
          HearingDay.to_hash(value[:hearing_day]).slice(:id, :scheduled_for, :request_type, :room).tap do |day|
            day[:hearings] = scheduled_hearings.map { |hearing| hearing.quick_to_hash(current_user_id) }
            day[:total_slots] = total_slots
          end
        end
      end.compact
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

    def find_hearing_day(request_type, hearing_key)
      find(hearing_key)
    rescue ActiveRecord::RecordNotFound
      HearingDayRepository.find_hearing_day(request_type, hearing_key)
    end

    private

    def hearing_days_to_array_of_days_and_hearings(total_video_and_co, _is_video_hearing)
      # We need to associate all of the hearing days from postgres with all of the
      # hearings from VACOLS. For efficiency we make one call to VACOLS and then
      # create a hash of the results using their ids.

      vacols_hearings_for_days = HearingRepository.fetch_hearings_for_parents(
        total_video_and_co.map { |hearing_day| hearing_day[:id] }
      )

      # Group the hearing days with the same keys as the hearings
      grouped_hearing_days = total_video_and_co.group_by do |hearing_day|
        hearing_day[:id].to_s
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
