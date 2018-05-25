FactoryBot.define do
  factory :case_issue, class: VACOLS::CaseIssue do
    sequence(:isskey)
    sequence(:issseq)

    issprog "01"
    isscode "02"
    issaduser "user"
    issadtime { Time.zone.now }

    trait :compensation do
      issprog "02"
      isscode "15"
      isslev1 "04"
      isslev2 "5252"
    end

    trait :education do
      issprog "03"
      isscode "02"
      isslev1 "01"
    end

    trait :disposition_remanded do
      issdc "3"
    end

    trait :disposition_denied do
      issdc "4"
    end

    trait :disposition_allowed do
      issdc "1"
    end
  end
end
