FactoryBot.define do
  factory :hearing do
    transient do
      case_hearing { create(:case_hearing, user: current_user) }
    end

    appeal { create(:legacy_appeal, vacols_case: create(:case, case_hearings: [case_hearing])) }
    vacols_id { case_hearing.hearing_pkseq }
  end
end
