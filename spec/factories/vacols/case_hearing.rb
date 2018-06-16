FactoryBot.define do
  factory :case_hearing, class: VACOLS::CaseHearing do
    hearing_type "V"
    hearing_date { Time.zone.today }
    room 1
    sequence(:vdkey, 1_000_000)

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


    # after(:build) do |hearing, _evaluator|
    #   # For video hearings we need to build the master record.
    #   # binding.pry
    #   if hearing.hearing_type == "V"
    #     create(:case_hearing, hearing_type: "C", hearing_pkseq: hearing.vdkey + "RO16")
    #   end
    # end
  end
end
