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

    after(:create) do |hearing, _evaluator|
      # For some reason the returned record's sequence is one less than what is actually saved.
      # We need to reload the correct record before trying to modify it.
      hearing.hearing_pkseq = hearing.hearing_pkseq + 1
      hearing.reload
    end

    after(:build) do |hearing, evaluator|
      # For video hearings we need to build the master record.
      if hearing.hearing_type == "V" && hearing.vdkey.nil?
        master_record = create(:case_hearing, hearing_type: "C", folder_nr: "VIDEO RO13")
        # For some reason the returned record's sequence is one less than what is actually saved.
        hearing.vdkey = master_record.hearing_pkseq
      end

      if evaluator.user
        hearing.board_member = create(:staff, :attorney_judge_role, user: evaluator.user).sattyid
      end
    end
  end
end
