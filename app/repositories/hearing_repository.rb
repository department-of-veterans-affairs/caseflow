class HearingRepository
  class << self
    def upcoming_hearings_for_judge(vacols_user_id, date_diff: 7.days)
      hearings_for(VACOLS::CaseHearing.upcoming_for_judge(vacols_user_id, date_diff: date_diff))
    end

    def hearings_for_appeal(appeal_vacols_id)
      hearings_for(VACOLS::CaseHearing.for_appeal(appeal_vacols_id))
    end

    private

    def hearings_for(case_hearings)
      case_hearings.map { |hearing| Hearing.load_from_vacols(hearing) }
    end
  end
end
