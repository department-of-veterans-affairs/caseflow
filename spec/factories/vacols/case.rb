FactoryBot.define do
  factory :case, class: VACOLS::Case do
    sequence(:bfkey)
    sequence(:bfcorkey)
    sequence(:bfcorlid, 10000) { |n| "#{n}S" }

    association :representative, factory: :representative, repkey: :bfkey
    association :correspondent, factory: :correspondent
    association :folder, factory: :folder, ticknum: :bfkey

    transient do
      documents do
        [
        ]
      end
      nod_document []
      soc_document []
      form9_document []
      ssoc_documents []
      decision_document []
    end

    factory :case_with_nod do
      bfdnod { 1.year.ago }
      transient do
        nod_document { [Document.new(type: "NOD", received_at: 1.year.ago)] }
      end

      factory :case_with_soc do
        bfdsoc { 6.months.ago }
        transient do
          soc_document { [Document.new(type: "SOC", received_at: 6.months.ago)] }
        end

        factory :case_with_form_9 do
          bfd19 { 3.months.ago }
          transient do
            form9_document { [Document.new(type: "Form9", received_at: 6.months.ago)] }
          end

          factory :case_with_notification_date do
            bfdrodec { 75.days.ago}

            factory :case_with_ssoc do
              transient do
                number_of_ssoc 2
              end
              transient do
                ssoc_documents do
                  [
                    Document.new(type: "SSOC", received_at: 2.months.ago),
                    Document.new(type: "SSOC", received_at: 1.months.ago),
                    Document.new(type: "SSOC", received_at: 10.day.ago),
                    Document.new(type: "SSOC", received_at: 5.days.ago),
                    Document.new(type: "SSOC", received_at: 2.days.ago)
                  ]
                end
              end

              bfssoc1 { 2.months.ago }
              bfssoc2 { 1.month.ago if number_of_ssoc > 1}
              bfssoc3 { 10.days.ago if number_of_ssoc > 2}
              bfssoc4 { 5.days.ago if number_of_ssoc > 3}
              bfssoc5 { 2.days.ago if number_of_ssoc > 4}

              factory :case_with_decision do
                bfddec { 1.day.ago}

                transient do
                  decision_document { [Document.new(type: "BVA Decision", received_at: 1.day.ago)] }
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
    
    after(:build) do |vacols_case, evaluator|
      Fakes::VBMSService.document_records ||= {}
      Fakes::VBMSService.document_records[vacols_case.bfcorlid] = evaluator.documents + evaluator.nod_document +
        evaluator.soc_document + evaluator.form9_document + evaluator.ssoc_documents + evaluator.decision_document

      # Fakes::VBMSService.manifest_vbms_fetched_at = attrs.delete(:manifest_vbms_fetched_at)
      # Fakes::VBMSService.manifest_vva_fetched_at = attrs.delete(:manifest_vva_fetched_at)
    end
  end
end