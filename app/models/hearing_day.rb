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
    serializable_hash(
      methods: [
        :judge_first_name,
        :judge_last_name,
        :readable_request_type,
        :total_slots
      ]
    )
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

  def judge_first_name
    judge ? judge.full_name.split(" ").first : nil
  end

  def judge_last_name
    judge ? judge.full_name.split(" ").last : nil
  end

  def readable_request_type
    Hearing::HEARING_TYPES[request_type.to_sym]
  end

  private

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

  class << self
    def create_hearing_day(hearing_hash)
      current_user_id = RequestStore.store[:current_user].id
      hearing_hash = hearing_hash.merge(
        created_by: current_user_css_id,
        updated_by: current_user_css_id,
        created_by_id: current_user_id,
        updated_by_id: current_user_id
      )
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

    def upcoming_days_for_vso_user(start_date, end_date, user)
      days_in_range = hearing_days_in_range(start_date, end_date)

      ama_days = days_in_range.select { |day| day.hearings.any? { |hearing| hearing.assigned_to_vso?(user) } }

      remaining_days = days_in_range.where.not(id: ama_days.pluck(:id)).order(:scheduled_for).limit(1000)

      vacols_hearings_for_remaining_days = HearingRepository.fetch_hearings_for_parents(remaining_days.map(&:id))

      loaded_hearings = LegacyHearing
        .includes(appeal: [tasks: :assigned_to])
        .where(id: vacols_hearings_for_remaining_days.values.flatten.pluck(:id))

      vacols_days = remaining_days.select do |day|
        vacols_hearing = vacols_hearings_for_remaining_days[day.id.to_s]

        vacols_hearing&.any? do |hearing|
          loaded_hearings.detect { |legacy_hearing| legacy_hearing.id == hearing.id }&.assigned_to_vso?(user)
        end
      end

      ama_days + vacols_days
    end

    def load_days(start_date, end_date, regional_office = nil)
      if regional_office.nil?
        where("DATE(scheduled_for) between ? and ?", start_date, end_date)
      elsif regional_office == REQUEST_TYPES[:central]
        where("request_type = ? and DATE(scheduled_for) between ? and ?", REQUEST_TYPES[:central], start_date, end_date)
      else
        where("regional_office = ? and DATE(scheduled_for) between ? and ?", regional_office, start_date, end_date)
      end
    end

    def list_upcoming_hearing_days(start_date, end_date, user, regional_office = nil)
      if user&.vso_employee?
        upcoming_days_for_vso_user(start_date, end_date, user)
      elsif user&.roles&.include?("Hearing Prep")
        upcoming_days_for_judge(start_date, end_date, user)
      else
        load_days(start_date, end_date, regional_office)
      end
    end

    def open_hearing_days_with_hearings_hash(start_date, end_date, regional_office = nil, current_user_id = nil)
      total_video_and_co = load_days(start_date, end_date, regional_office)
      vacols_hearings_for_days = HearingRepository.fetch_hearings_for_parents(total_video_and_co.pluck(:id))

      total_video_and_co.map do |hearing_day|
        all_hearings = (hearing_day.hearings || []) + (vacols_hearings_for_days[hearing_day.id.to_s] || [])
        scheduled_hearings = filter_non_scheduled_hearings(all_hearings || [])

        if scheduled_hearings.length >= hearing_day.total_slots || hearing_day.lock
          nil
        else
          hearing_day.to_hash.merge(
            "hearings" => scheduled_hearings.map { |hearing| hearing.quick_to_hash(current_user_id) }
          )
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

    private

    def hearing_days_in_range(start_date, end_date)
      HearingDay.includes(hearings: [appeal: [tasks: :assigned_to]])
        .where("DATE(scheduled_for) between ? and ?", start_date, end_date)
    end

    def current_user_css_id
      RequestStore.store[:current_user].css_id.upcase
    end
  end
end
