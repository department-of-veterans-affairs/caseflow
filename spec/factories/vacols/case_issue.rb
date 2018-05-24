FactoryBot.define do
  factory :case_issue, class: VACOLS::CaseIssue do
    sequence(:isskey)
    sequence(:issseq)

    issprog "01"
    isscode "02"
    issaduser "user"
    issadtime { DateTime.now }

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
