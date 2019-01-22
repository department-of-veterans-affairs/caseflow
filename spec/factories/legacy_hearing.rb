FactoryBot.define do
  factory :legacy_hearing do
    scheduled_for { Time.zone.today }

    transient do
      case_hearing { create(:case_hearing, user: user, hearing_date: scheduled_for) }
    end

    appeal do
      create(:legacy_appeal, vacols_case: create(:case_with_form_9, case_issues:
        [create(:case_issue), create(:case_issue)], case_hearings: [case_hearing]))
    end

    vacols_id { case_hearing.hearing_pkseq }
  end
end
