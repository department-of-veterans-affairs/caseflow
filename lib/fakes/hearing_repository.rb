class Fakes::HearingRepository
  class << self
    attr_accessor :hearing_records
  end

  def self.upcoming_hearings_for_judge(vacols_user_id, date_diff: 7.days.ago)
    user = User.find_by_vacols_id(vacols_user_id)
    (hearing_records || []).select { |h| h.user_id == user.id && date_diff }
  end

  def self.seed!
    user = User.find_by_vacols_id("LROTH")
    50.times.each do |i|
      type = VACOLS::CaseHearing::HEARING_TYPES.values[i % 3]
      Generators::Hearing.build(
        type: type,
        date: Time.zone.now - (i % 9).days - rand(3).days,
        user: user
      )
    end
  end
end
