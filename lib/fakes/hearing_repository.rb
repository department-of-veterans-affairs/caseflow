require "prime"
class Fakes::HearingRepository
  class << self
    attr_accessor :hearing_records
  end

  def self.upcoming_hearings_for_judge(css_id)
    user = User.find_by_css_id(css_id)
    (hearing_records || []).select { |h| h.user_id == user.id }
  end

  def self.hearings_for_appeal(appeal_vacols_id)
    appeal = Appeal.find_by(vacols_id: appeal_vacols_id)
    return [] unless appeal
    (hearing_records || []).select { |h| h.appeal_id == appeal.id }
  end

  def self.update_vacols_hearing!(vacols_record, hearing_info)
    return if (hearing_info.keys.map(&:to_sym) & [:notes, :aod, :disposition, :hold_open, :transcript_requested]).empty?
    hearing = find_by_vacols_id(vacols_record[:vacols_id])
    hearing.assign_from_vacols(hearing_info)
  end

  def self.load_vacols_data(hearing)
    return false if hearing_records.blank?
    record = find_by_vacols_id(hearing.vacols_id)

    return false unless record
    hearing.assign_from_vacols(vacols_record: record.vacols_record)
    true
  end

  def self.find_by_vacols_id(vacols_id)
    hearing_records.find { |h| h.vacols_id == vacols_id }
  end

  def self.find_by_id(id)
    hearing_records.find { |h| h.id == id }
  end

  def self.clean!
    self.hearing_records = []
  end

  def self.seed!
    user = User.find_by_css_id("Hearing Prep")
    50.times.each { |i| Generators::Hearing.create(random_attrs(i).merge(user: user)) }
  end

  def self.random_attrs(i)
    {
      vacols_record: OpenStruct.new(vacols_id: 950_330_575 + (i * 1465)),
      type: VACOLS::CaseHearing::HEARING_TYPES.values[i % 3],
      date: Time.zone.now - (i % 9).days - rand(3).days,
      vacols_id: 950_330_575 + (i * 1465),
      disposition: VACOLS::CaseHearing::HEARING_DISPOSITIONS.values[i % 4],
      aod: [VACOLS::CaseHearing::HEARING_AODS.values[i % 3], nil].sample,
      hold_open: [30, 60, 90].sample,
      notes: Prime.prime?(i) ? "The Veteran had active service from November 1989 to November 1990" : nil,
      transcript_requested: [VACOLS::CaseHearing::BOOLEAN_MAP.values[i % 2], nil].sample
    }
  end
end
