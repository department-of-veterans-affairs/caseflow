require "prime"
class Fakes::HearingRepository
  class << self
    attr_accessor :hearing_records
    attr_accessor :master_records
  end

  def self.upcoming_hearings_for_judge(css_id)
    user = User.find_by_css_id(css_id)
    records.select { |h| h.user_id == user.id }
  end

  def self.records
    (hearing_records || []) + (master_records || [])
  end

  def self.hearings_for_appeal(appeal_vacols_id)
    appeal = Appeal.find_by(vacols_id: appeal_vacols_id)
    return [] unless appeal
    (hearing_records || []).select { |h| h.appeal_id == appeal.id }
  end

  def self.hearings_for_appeals(appeal_vacols_ids)
    appeal_vacols_ids.map { |vacols_id| hearings_for_appeal(vacols_id) }
  end

  def self.update_vacols_hearing!(vacols_record, hearing_info)
    return if (hearing_info.keys.map(&:to_sym) &
        [:notes, :aod, :disposition, :add_on, :hold_open, :transcript_requested, :representative_name]).empty?
    hearing = find_by_vacols_id(vacols_record[:vacols_id].to_s)
    hearing.assign_from_vacols(hearing_info)
  end

  def self.load_vacols_data(hearing)
    return false if hearing_records.blank?
    record = find_by_vacols_id(hearing.vacols_id)

    return false unless record
    hearing.assign_from_vacols(record.vacols_attributes)
    true
  end

  def self.number_of_slots(*); end

  def self.appeals_ready_for_hearing(vbms_id)
    Fakes::AppealRepository.appeals_ready_for_hearing(vbms_id)
  end

  def self.find_by_vacols_id(vacols_id)
    hearing_records.find { |h| h.vacols_id == vacols_id }
  end

  def self.find_by_id(id)
    hearing_records.find { |h| h.id == id }
  end

  def self.find_index_by_id(id)
    hearing_records.index { |h| h.id == id }
  end

  def self.find_by_date(date)
    master_records.find { |h| h.date.to_date == date }
  end

  def self.clean!
    self.hearing_records = []
  end

  def self.create_hearing_for_appeal(i, appeal)
    user = User.find_by_css_id("Hearing Prep")
    Generators::Hearing.create(random_attrs(i).merge(user: user, appeal: appeal))
  end

  def self.create_already_held_hearing_for_appeal(i, appeal)
    user = User.find_by_css_id("Hearing Prep")
    attrs = random_attrs(i)
    attrs[:disposition] = :held
    Generators::Hearing.create(random_attrs(i).merge(user: user, appeal: appeal))
  end

  def self.seed!
    user = User.find_by_css_id("Hearing Prep")
    50.times.each { |i| Generators::Hearing.create(random_attrs(i).merge(user: user)) }
    2.times.each { |i| Generators::Hearings::MasterRecord.build(user_id: user.id, date: Time.zone.now + (i + 6).days) }
  end

  def self.random_attrs(i)
    {
      vacols_record: OpenStruct.new(vacols_id: 950_330_575 + (i * 1465)),
      type: VACOLS::CaseHearing::HEARING_TYPES.values[i % 3],
      date: Time.zone.now - (i % 9).days - rand(3).days - rand(2).hours + rand(60).minutes,
      vacols_id: 950_330_575 + (i * 1465),
      disposition: nil,
      aod: nil,
      hold_open: nil,
      add_on: false,
      notes: Prime.prime?(i) ? "The Veteran had active service from November 1989 to November 1990" : nil,
      transcript_requested: false
    }
  end
end
