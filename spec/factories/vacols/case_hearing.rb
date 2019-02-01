FactoryBot.define do
  factory :case_hearing, class: VACOLS::CaseHearing do
    hearing_type "V"
    hearing_date { Time.zone.today }
    room 1
    folder_nr { create(:case).bfkey }

    transient do
      user nil
    end

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

    after(:create) do |hearing, _evaluator|
      # For some reason the returned record's sequence is one less than what is actually saved.
      # We need to reload the correct record before trying to modify it.
      hearing.hearing_pkseq = hearing.hearing_pkseq + 1
      hearing.reload
    end

    after(:build) do |hearing, evaluator|
      # Build Caseflow hearing day and associate with legacy hearing.
      regional_office = (hearing.hearing_type == "V") ? "RO13" : nil
      master_record = create(:hearing_day, request_type: hearing.hearing_type, regional_office: regional_office)
      hearing.vdkey = master_record.id

      if evaluator.user
        hearing.board_member = create(:staff, :attorney_judge_role, user: evaluator.user).sattyid
      end
    end
  end
end
