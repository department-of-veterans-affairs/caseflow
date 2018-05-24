FactoryBot.define do
  factory :case, class: VACOLS::Case do
    sequence(:bfkey)
    sequence(:bfcorkey)
    sequence(:bfcorlid, 10_000) { |n| "#{n}S" }

    association :representative, factory: :representative, repkey: :bfkey
    association :correspondent, factory: :correspondent
    association :folder, factory: :folder, ticknum: :bfkey

    trait :assigned do
      transient do
        decass_count 1
      end

      after(:create) do |vacols_case, evaluator|
        create_list(:decass, evaluator.decass_count, defolder: vacols_case.bfkey)
      end
    end

    transient do
      case_issues []

      after(:create) do |vacols_case, evaluator|
        evaluator.case_issues.each do |case_issue|
          case_issue.isskey = vacols_case.bfkey
          case_issue.save
        end
      end
    end

    transient do
      documents []
      nod_document []
      soc_document []
      form9_document []
      ssoc_documents []
      decision_document []
    end

    factory :case_with_nod do
      bfdnod { 1.year.ago }
      transient do
        nod_document { [create(:document, type: "NOD", received_at: 1.year.ago)] }
      end

      factory :case_with_soc do
        bfdsoc { 6.months.ago }
        transient do
          soc_document { [create(:document, type: "SOC", received_at: 6.months.ago)] }
        end

        factory :case_with_notification_date do
          bfdrodec { 75.days.ago }

          factory :case_with_form_9 do
            bfd19 { 3.months.ago }
            transient do
              form9_document { [create(:document, type: "Form 9", received_at: 3.months.ago)] }
            end

            factory :case_with_ssoc do
              transient do
                number_of_ssoc 2
              end
              transient do
                ssoc_documents do
                  [
                    create(:document, type: "SSOC", received_at: 2.months.ago),
                    create(:document, type: "SSOC", received_at: 1.month.ago),
                    create(:document, type: "SSOC", received_at: 10.days.ago),
                    create(:document, type: "SSOC", received_at: 5.days.ago),
                    create(:document, type: "SSOC", received_at: 2.days.ago)
                  ][0..number_of_ssoc]
                end
              end

              bfssoc1 { 2.months.ago }
              bfssoc2 { 1.month.ago if number_of_ssoc > 1 }
              bfssoc3 { 10.days.ago if number_of_ssoc > 2 }
              bfssoc4 { 5.days.ago if number_of_ssoc > 3 }
              bfssoc5 { 2.days.ago if number_of_ssoc > 4 }

              factory :case_with_decision do
                bfddec { 1.day.ago }

                transient do
                  decision_document { [create(:document, type: "BVA Decision", received_at: 1.day.ago)] }
                end
              end
            end
          end
        end
      end
    end

    trait :original do
      bfac 1
    end

    trait :reconsideration do
      bfac 4
    end

    trait :certified do
      transient do
        certification_date 1.day.ago
      end

      bfdcertool { certification_date }
      bf41stat { certification_date }
    end

    trait :status_active do
      bfmpro "ACT"
    end

    trait :status_remand do
      bfmpro "REM"
    end

    trait :status_complete do
      bfmpro "HIS"
    end

    trait :status_advance do
      bfmpro "ADV"
    end

    trait :disposition_allowed do
      bfdc "1"
    end

    trait :disposition_remanded do
      bfdc "3"
    end

    trait :disposition_vacated do
      bfdc "5"
    end

    trait :disposition_ramp do
      bfdc "P"
    end

    after(:build) do |vacols_case, evaluator|
      Fakes::VBMSService.document_records ||= {}
      Fakes::VBMSService.document_records[vacols_case.bfcorlid] =
        evaluator.documents + evaluator.nod_document + evaluator.soc_document +
        evaluator.form9_document + evaluator.ssoc_documents + evaluator.decision_document
    end
  end
end
