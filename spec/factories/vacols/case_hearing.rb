FactoryBot.define do
  factory :case_hearing, class: VACOLS::CaseHearing do
    sequence(:hearing_pkseq)
    hearing_type "V"
    hearing_date { Time.zone.today }

    trait :disposition_held do
      hearing_disp "H"
    end

    trait :disposition_cancelled do
      hearing_disp "C"
    end

    trait :disposition_postponed do
      hearing_disp "P"
    end

    trait :disposition_no_show do
      hearing_disp "N"
    end
  end
end
