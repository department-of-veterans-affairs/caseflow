class HearingRepository
  def self.upcoming_hearings_for_judge(vacols_user_id, date_diff: 7.days)
    VACOLS::CaseHearing.upcoming_for_judge(vacols_user_id, date_diff: date_diff).map do |hearing|
      Hearing.load_from_vacols(hearing, vacols_user_id)
    end
  end
end
