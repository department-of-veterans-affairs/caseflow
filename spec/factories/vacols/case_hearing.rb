FactoryBot.define do
  factory :case_hearing, class: VACOLS::CaseHearing do
    hearing_type "V"
    hearing_date { Time.zone.today }
    room 1

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

    after(:create) do |hearing, evaluator|
      hearing.hearing_pkseq = hearing.hearing_pkseq + 1
      hearing.reload
      if evaluator.user
        staff = create(:staff, :attorney_judge_role, sdomainid: evaluator.user.css_id)
        hearing.update(board_member: staff.sattyid)
      end
    end

    after(:build) do |hearing, _evaluator|
      # For video hearings we need to build the master record.
      if hearing.hearing_type == "V"
        master_record = create(:case_hearing, hearing_type: "C", folder_nr: "VIDEO RO13")
        # For some reason the returned record's sequence is one less than what is actually saved.
        hearing.vdkey = master_record.hearing_pkseq + 1
      end
    end
  end
end
