# frozen_string_literal: true

FactoryBot.define do
  factory :case, class: VACOLS::Case do
    sequence(:bfkey)
    sequence(:bfcorkey)
    sequence(:bfcorlid, 300_000_000) { |n| "#{n}S" }

    association :correspondent, factory: :correspondent
    association :folder, factory: :folder, ticknum: :bfkey

    bfregoff { "RO18" }
    bfcurloc { "CASEFLOW" }

    trait :assigned do
      transient do
        decass_count { 1 }
        user { nil }
        assigner { nil }
        work_product { nil }
        document_id { nil }
      end

      after(:create) do |vacols_case, evaluator|
        if evaluator.user
          existing_staff = VACOLS::Staff.find_by_sdomainid(evaluator.user.css_id)
          staff = (existing_staff || create(:staff, user: evaluator.user))
          slogid = staff.slogid
          sattyid = staff.sattyid
        end
        if evaluator.assigner
          existing_assigner = VACOLS::Staff.find_by_sdomainid(evaluator.assigner.css_id)
          assigner_slogid = (existing_assigner || create(:staff, user: evaluator.assigner)).slogid
        end
        vacols_case.update!(bfcurloc: slogid) if slogid

        create_list(
          :decass,
          evaluator.decass_count,
          evaluator.work_product,
          defolder: vacols_case.bfkey,
          deadusr: slogid || "TEST",
          demdusr: assigner_slogid || "ASSIGNER",
          dereceive: (evaluator.user&.vacols_roles&.include?("judge")) ? Time.zone.today : nil,
          dedocid: evaluator.document_id || nil,
          deatty: sattyid || "100"
        )
      end
    end

    transient do
      # Pass an array of built (not created) case_hearings to associate with this appeal
      case_hearings { [] }

      after(:create) do |vacols_case, evaluator|
        evaluator.case_hearings.each do |case_hearing|
          case_hearing.update!(folder_nr: vacols_case.bfkey)
        end
      end
    end

    transient do
      case_issues { [] }

      after(:create) do |vacols_case, evaluator|
        evaluator.case_issues.each do |case_issue|
          case_issue.isskey = vacols_case.bfkey
          case_issue.issseq = VACOLS::CaseIssue.generate_sequence_id(vacols_case.bfkey)
          case_issue.save
        end
      end
    end

    transient do
      documents { [] }
      nod_document { [] }
      soc_document { [] }
      form9_document { [] }
      ssoc_documents { [] }
      decision_document { [] }
    end

    factory :case_with_rep_table_record do
      transient do
        after(:create) do |vacols_case|
          create(:representative, repkey: vacols_case.bfkey)
        end
      end
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
                number_of_ssoc { 2 }
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

              factory :case_with_old_decision do
                bfddec { 1.day.ago }

                transient do
                  decision_document { [create(:document, type: "BVA Decision", received_at: 7.days.ago)] }
                end
              end
            end
          end
        end
      end
    end

    trait :selected_for_quality_review do
      after(:create) do |vacols_case|
        create(:decision_quality_review, qrfolder: vacols_case.bfkey)
      end
    end

    trait :type_original do
      bfac { "1" }
    end

    trait :type_post_remand do
      bfac { "3" }
    end

    trait :type_reconsideration do
      bfac { "4" }
    end

    trait :type_cavc_remand do
      bfac { "7" }
    end

    trait :certified do
      transient do
        certification_date { 1.day.ago }
      end

      bfdcertool { certification_date }
      bf41stat { certification_date }
    end

    trait :status_active do
      bfmpro { "ACT" }
    end

    trait :status_remand do
      bfmpro { "REM" }
      bfdc { "3" }
    end

    trait :status_complete do
      bfmpro { "HIS" }
    end

    trait :status_advance do
      bfmpro { "ADV" }
    end

    trait :status_motion do
      bfmpro { "MOT" }
    end

    trait :disposition_allowed do
      bfdc { "1" }
    end

    trait :disposition_remanded do
      bfdc { "3" }
    end

    trait :disposition_vacated do
      bfdc { "5" }
    end

    trait :disposition_granted_by_aoj do
      bfdc { "B" }
    end

    trait :disposition_merged do
      bfdc { "M" }
    end

    trait :disposition_ramp do
      bfdc { "P" }
    end

    trait :representative_american_legion do
      bfso { "A" }
    end

    trait :video_hearing_requested do
      bfdocind { "V" }
      bfcurloc { "57" }
      bfhr { "2" }
      bfac { "7" }
    end

    trait :central_office_hearing do
      bfhr { "1" }
      bfcurloc { "57" }
      bfac { "7" }
    end

    trait :travel_board_hearing do
      bfhr { "2" }
    end

    trait :reopenable do
      bfmpro { "HIS" }
      bfcurloc { "99" }
      bfboard { "00" }

      after(:create) do |vacols_case, _evaluator|
        create(:priorloc,
               lockey: vacols_case.bfkey,
               locstto: "77",
               locdin: Time.zone.today - 6,
               locdout: Time.zone.today - 2)
      end
    end

    trait :aod do
      after(:create) do |vacols_case, _evaluator|
        create(:note, tsktknm: vacols_case.bfkey, tskactcd: "B")
      end
    end

    trait :docs_in_vbms do
      after(:build) do |vacols_case, _evaluator|
        vacols_case.folder.tivbms = %w[Y 1 0].sample
      end
    end

    trait :docs_in_vva do
      after(:build) do |vacols_case, _evaluator|
        vacols_case.folder.tisubj2 = "Y"
      end
    end

    trait :paper_case do
      after(:build) do |vacols_case, _evaluator|
        vacols_case.folder.tivbms = "N" if %w[Y 1 0].include?(vacols_case.folder.tivbms)
        vacols_case.folder.tisubj2 = "N" if vacols_case.folder.tisubj2&.eq?("Y")
      end
    end

    transient do
      remand_return_date { nil }

      after(:create) do |vacols_case, evaluator|
        if evaluator.remand_return_date
          create(:priorloc, lockey: vacols_case.bfkey, locstto: "96", locdout: evaluator.remand_return_date)
        end
      end
    end

    transient do
      staff { nil }
    end

    after(:build) do |vacols_case, evaluator|
      if evaluator.staff
        vacols_case.bfcurloc = evaluator.staff.slogid
      end
    end

    after(:build) do |vacols_case, evaluator|
      Fakes::VBMSService.document_records ||= {}
      Fakes::VBMSService.document_records[vacols_case.bfcorlid.gsub(/[^0-9]/, "")] =
        evaluator.documents + evaluator.nod_document + evaluator.soc_document +
        evaluator.form9_document + evaluator.ssoc_documents + evaluator.decision_document
    end
  end
end
