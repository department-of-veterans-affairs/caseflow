FactoryBot.define do
  factory :case_hearing, class: VACOLS::CaseHearing do
    hearing_type { HearingDay::REQUEST_TYPES[:video] }
    hearing_date { Time.zone.today }
    room { 1 }
    folder_nr { create(:case).bfkey }

    transient do
      user { nil }
    end

    trait :disposition_held do
      hearing_disp { "H" }
    end

    trait :disposition_cancelled do
      hearing_disp { "C" }
    end

    trait :disposition_postponed do
      hearing_disp { "P" }
    end

    trait :disposition_no_show do
      hearing_disp { "N" }
    end

    after(:create) do |hearing, _evaluator|
      # For some reason the returned record's sequence is one less than what is actually saved.
      # We need to reload the correct record before trying to modify it.
      hearing.hearing_pkseq = hearing.hearing_pkseq + 1
      hearing.reload
    end

    after(:build) do |hearing, evaluator|
      # Build Caseflow hearing day and associate with legacy hearing.
      if hearing.vdkey.nil?
        master_record = if hearing.hearing_type == HearingDay::REQUEST_TYPES[:central]
                          create(:hearing_day,
                                 scheduled_for: hearing.hearing_date,
                                 request_type: hearing.hearing_type)
                        else
                          create(:case_hearing,
                                 hearing_type: HearingDay::REQUEST_TYPES[:central],
                                 hearing_date: hearing.hearing_date,
                                 folder_nr: "VIDEO RO13")
                        end
        hearing.vdkey = master_record.id
      end

      if evaluator.user
        hearing.board_member = create(:staff, :attorney_judge_role, user: evaluator.user).sattyid
      end
    end
  end
end
