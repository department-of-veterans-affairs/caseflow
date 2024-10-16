# frozen_string_literal: true

# When using this factory, pass in a pre-created veteran's file_number as the bfcorlid: arg
# This ensures that the case is created with the correct veteran_file_number association, and ensures that
# no unique index constraints are violated between VACOLS and Caseflow.
#
# Additionally, this factory should be used in conjuction with the :legacy_appeal factory when a caseflow
# legacy appeal object is needed. Pass a case created by this factory into :legacy_appeal as vacols_case:
# to ensure the correct associations are made between a veteran, case, and legacy appeal.

FactoryBot.define do
  factory :case, class: VACOLS::Case do
    bfkey { generate :vacols_case_key } # a.k.a. VACOLS_ID
    bfcorkey { generate :vacols_correspondent_key }
    bfcorlid { "#{generate :veteran_file_number}S" }

    correspondent { association :correspondent }

    transient do
      docket_number { "150000#{bfkey}" }
    end
    # folder.tinum is the docket_number
    folder { association :folder, ticknum: bfkey, tinum: docket_number, titrnum: bfcorlid }

    bfregoff { "RO18" }

    before(:create) do |vacols_case, evaluator|
      vacols_case.bfdloout =
        if evaluator.bfdloout
          VacolsHelper.format_datetime_with_utc_timezone(evaluator.bfdloout)
        else
          VacolsHelper.local_time_with_utc_timezone
        end
    end

    trait :assigned do
      transient do
        decass_count { 1 }
        user { nil }
        assigner { nil }
        work_product { nil }
        document_id { nil }
        as_judge_assign_task { nil }
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

        # Set the Work Product
        deprod = if evaluator.work_product && evaluator.work_product.length > 3
                   evaluator.work_product[0..2].upcase
                 else
                   evaluator.work_product
                 end

        # If user=judge and dereceive=nil, then reassigned_to_judge_date=nil, resulting in a JudgeLegacyAssignTask.
        # If user=judge and dereceive!=nil, then this results in a JudgeLegacyDecisionReviewTask.
        # Otherwise AttorneyLegacyTask will result.
        dereceive = if evaluator.user&.vacols_roles&.include?("judge")
                      evaluator.as_judge_assign_task ? nil : Time.zone.today
                    end

        create_list(
          :decass,
          evaluator.decass_count,
          deprod: deprod,
          defolder: vacols_case.bfkey,
          deadusr: slogid || "TEST",
          demdusr: assigner_slogid || "ASSIGNER",
          dereceive: dereceive,
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

              factory :case_with_multi_decision do
                bfddec { 1.day.ago }

                transient do
                  decision_document do
                    [
                      create(:document, type: "BVA Decision", received_at: 1.day.ago),
                      create(:document, type: "BVA Decision", received_at: 1.day.ago)
                    ]
                  end
                end
              end

              factory :case_with_old_decision do
                bfddec { 1.day.ago }

                transient do
                  decision_document { [create(:document, type: "BVA Decision", received_at: 7.days.ago)] }
                end
              end
            end

            # The judge and attorney should be the VACOLS::Staff records of those users
            # This factory uses the :aod trait to mark it AOD instead of a transient attribute
            # Pass `tied_to: false` to create an original appeal without a previous hearing
            factory :legacy_signed_appeal do
              transient do
                judge { nil }
                signing_avlj { nil }
                assigned_avlj { nil }
                attorney { nil }
                cavc { false }
                appeal_affinity { true }
                affinity_start_date { 2.months.ago }
                tied_to { true }
              end

              status_active

              bfdpdcn { 1.month.ago }
              bfcurloc { "81" }

              after(:create) do |new_case, evaluator|
                signing_judge =
                  if evaluator.signing_avlj.present?
                    VACOLS::Staff.find_by_sdomainid(evaluator.signing_avlj.css_id)
                  else
                    evaluator.judge || create(:user, :judge, :with_vacols_judge_record).vacols_staff
                  end

                hearing_judge =
                  if evaluator.assigned_avlj.present?
                    VACOLS::Staff.find_by_sdomainid(evaluator.assigned_avlj.css_id)
                  else
                    evaluator.judge || create(:user, :judge, :with_vacols_judge_record).vacols_staff
                  end

                signing_sattyid = signing_judge.sattyid

                original_attorney = evaluator.attorney || create(:user, :with_vacols_attorney_record).vacols_staff

                new_case.correspondent.update!(ssn: new_case.bfcorlid.chomp("S")) unless new_case.correspondent.ssn

                veteran = Veteran.find_by_file_number_or_ssn(new_case.correspondent.ssn)

                if veteran
                  new_case.correspondent.update!(snamef: veteran.first_name, snamel: veteran.last_name)
                else
                  create(
                    :veteran,
                    first_name: new_case.correspondent.snamef,
                    last_name: new_case.correspondent.snamel,
                    name_suffix: new_case.correspondent.ssalut,
                    ssn: new_case.correspondent.ssn,
                    file_number: new_case.correspondent.ssn
                  )
                end

                # Build these instead of create so the folder after_create hooks don't execute and create another case
                # until the original case has been created and the associations saved
                original_folder = build(
                  :folder,
                  new_case.folder.attributes.except!("ticknum", "tidrecv", "tidcls", "tiaduser",
                                                     "tiadtime", "tikeywrd", "tiread2", "tioctime", "tiocuser",
                                                     "tidktime", "tidkuser")
                )

                original_issues = new_case.case_issues.map do |issue|
                  build(
                    :case_issue,
                    issue.attributes.except("isskey", "issaduser", "issadtime", "issmduser", "issmdtime", "issdcls"),
                    issdc: "3"
                  )
                end

                original_case = create(
                  :case,
                  :status_complete,
                  :disposition_remanded,
                  bfac: evaluator.cavc ? "7" : "1",
                  bfcorkey: new_case.bfcorkey,
                  bfcorlid: new_case.bfcorlid,
                  bfdnod: new_case.bfdnod,
                  bfdsoc: new_case.bfdsoc,
                  bfd19: new_case.bfd19,
                  bfcurloc: "99",
                  bfddec: new_case.bfdpdcn,
                  bfmemid: signing_sattyid,
                  bfattid: original_attorney.sattyid,
                  folder: original_folder,
                  correspondent: new_case.correspondent,
                  case_issues: original_issues
                )

                if evaluator.tied_to
                  create(
                    :case_hearing,
                    :disposition_held,
                    folder_nr: original_case.bfkey,
                    hearing_date: original_case.bfddec - 1.month,
                    user: User.find_by_css_id(hearing_judge&.sdomainid)
                  )
                end

                if evaluator.appeal_affinity
                  create(:appeal_affinity, appeal: new_case, affinity_start_date: evaluator.affinity_start_date)
                end
              end
            end

            # You can change the judge, attorney, AOD status, and Appeal Affinity of your Legacy CAVC Appeal.
            # The Appeal_Affinity is default but the AOD must be toggled on. Example:
            # "FactoryBot.create(:legacy_cavc_appeal, judge: judge, aod: true, affinity_start_date: 2.weeks.ago)"

            factory :legacy_cavc_appeal do
              transient do
                judge { nil }
                attorney { nil }
                aod { false }
                cavc { true }
                appeal_affinity { true }
                affinity_start_date { 1.month.ago }
                tied_to { true }
              end

              bfmpro { "HIS" }
              bfddec { 1.day.ago }
              bfac { "1" }
              bfdc { "3" }
              bfcurloc { "99" }

              after(:create) do |vacols_case, evaluator|
                vacols_case.bfmemid = if evaluator.judge
                                        existing_judge = VACOLS::Staff.find_by_sattyid(evaluator.judge.sattyid)
                                        existing_judge.sattyid
                                      else
                                        new_judge = create(:staff, :judge_role, user: evaluator.judge)
                                        new_judge.sattyid
                                      end

                vacols_case.bfattid = if evaluator.attorney
                                        existing_attorney = VACOLS::Staff.find_by_sattyid(evaluator.attorney.sattyid)
                                        existing_attorney.sattyid
                                      else
                                        new_attorney = create(:staff, :attorney_role, user: evaluator.attorney)
                                        new_attorney.sattyid
                                      end

                vacols_case.case_issues.each do |case_issue|
                  case_issue.issdc = "3"
                  case_issue.save
                end

                vacols_case.correspondent.update!(ssn: vacols_case.bfcorlid.chomp("S"))
                vacols_case.save

                if Veteran.find_by_file_number_or_ssn(vacols_case.correspondent.ssn)
                  veteran = Veteran.find_by_file_number_or_ssn(vacols_case.correspondent.ssn)
                  vacols_case.correspondent.update!(snamef: veteran.first_name, snamel: veteran.last_name)
                else
                  create(
                    :veteran,
                    first_name: vacols_case.correspondent.snamef,
                    last_name: vacols_case.correspondent.snamel,
                    name_suffix: vacols_case.correspondent.ssalut,
                    ssn: vacols_case.correspondent.ssn,
                    file_number: vacols_case.correspondent.ssn
                  )
                end

                if evaluator.tied_to
                  create(
                    :case_hearing,
                    :disposition_held,
                    folder_nr: vacols_case.bfkey,
                    hearing_date: 5.days.ago.to_date,
                    user: User.find_by_css_id(evaluator.judge.sdomainid)
                  )
                end

                params = {
                  bfdpdcn: vacols_case.bfddec,
                  bfac: "7",
                  bfcurloc: "81",
                  bfcorkey: vacols_case.bfcorkey,
                  bfcorlid: vacols_case.bfcorlid,
                  bfdnod: vacols_case.bfdnod,
                  bfdsoc: vacols_case.bfdsoc,
                  bfd19: vacols_case.bfd19,
                  bfmpro: "ACT",
                  correspondent: vacols_case.correspondent,
                  folder_number_equal: true,
                  original_case: vacols_case,
                  case_issues_equal: true,
                  original_case_issues: vacols_case.case_issues
                }

                if !evaluator.cavc
                  params[:bfac] = "1"
                end

                cavc_appeal = if evaluator.aod
                                create(
                                  :case,
                                  :aod,
                                  params
                                )
                              else
                                create(
                                  :case,
                                  params
                                )
                              end

                if evaluator.appeal_affinity
                  create(:appeal_affinity, appeal: cavc_appeal, affinity_start_date: evaluator.affinity_start_date)
                end
              end
            end

            # The judge and attorney should be the VACOLS::Staff records of those users
            # This factory uses the :aod trait to mark it AOD instead of a transient attribute
            # Pass `tied_to: false` to create an original appeal without a previous hearing
            factory :legacy_aoj_appeal do
              transient do
                judge { nil }
                attorney { nil }
                cavc { false }
                appeal_affinity { true }
                affinity_start_date { 60.days.ago }
                tied_to { true }
                hearing_after_decision { false }
              end

              status_active
              type_post_remand

              bfdpdcn { 2.months.ago }
              bfcurloc { "81" }

              after(:create) do |new_case, evaluator|
                original_judge = evaluator.judge || create(:user, :judge, :with_vacols_judge_record).vacols_staff
                original_attorney = evaluator.attorney || create(:user, :with_vacols_attorney_record).vacols_staff

                new_case.correspondent.update!(ssn: new_case.bfcorlid.chomp("S")) unless new_case.correspondent.ssn

                veteran = Veteran.find_by_file_number_or_ssn(new_case.correspondent.ssn)

                if veteran
                  new_case.correspondent.update!(snamef: veteran.first_name, snamel: veteran.last_name)
                else
                  create(
                    :veteran,
                    first_name: new_case.correspondent.snamef,
                    last_name: new_case.correspondent.snamel,
                    name_suffix: new_case.correspondent.ssalut,
                    ssn: new_case.correspondent.ssn,
                    file_number: new_case.correspondent.ssn
                  )
                end

                # Build these instead of create so the folder after_create hooks don't execute and create another case
                # until the original case has been created and the associations saved
                original_folder = build(
                  :folder,
                  new_case.folder.attributes.except!("ticknum", "tidrecv", "tidcls", "tiaduser",
                                                     "tiadtime", "tikeywrd", "tiread2", "tioctime", "tiocuser",
                                                     "tidktime", "tidkuser")
                )

                original_issues = new_case.case_issues.map do |issue|
                  build(
                    :case_issue,
                    issue.attributes.except("isskey", "issaduser", "issadtime", "issmduser", "issmdtime", "issdcls"),
                    issdc: "3"
                  )
                end

                original_case = create(
                  :case,
                  :status_complete,
                  :disposition_remanded,
                  bfac: evaluator.cavc ? "7" : "1",
                  bfcorkey: new_case.bfcorkey,
                  bfcorlid: new_case.bfcorlid,
                  bfdnod: new_case.bfdnod,
                  bfdsoc: new_case.bfdsoc,
                  bfd19: new_case.bfd19,
                  bfcurloc: "99",
                  bfddec: new_case.bfdpdcn,
                  bfmemid: original_judge.sattyid,
                  bfattid: original_attorney.sattyid,
                  folder: original_folder,
                  correspondent: new_case.correspondent,
                  case_issues: original_issues
                )

                if evaluator.tied_to
                  create(
                    :case_hearing,
                    :disposition_held,
                    folder_nr: original_case.bfkey,
                    hearing_date: evaluator.hearing_after_decision ? original_case.bfddec + 1.month : original_case.bfddec - 1.month, # rubocop:disable Layout/LineLength
                    user: User.find_by_css_id(original_judge.sdomainid)
                  )
                end

                if evaluator.appeal_affinity
                  create(:appeal_affinity, appeal: new_case, affinity_start_date: evaluator.affinity_start_date)
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

    trait :tied_to_judge do
      transient do
        tied_judge { nil }
      end

      after(:create) do |vacols_case, evaluator|
        if evaluator.correspondent&.ssn
          VACOLS::Folder.find_by(tinum: evaluator.docket_number).update!(titrnum: evaluator.correspondent.ssn)
        else
          VACOLS::Folder.find_by(tinum: evaluator.docket_number).update!(titrnum: "123456789S")
        end

        create(
          :case_hearing,
          :disposition_held,
          folder_nr: vacols_case.bfkey,
          hearing_date: 5.days.ago.to_date,
          user: evaluator.tied_judge
        )
      end
    end

    trait :tied_to_previous_judge do
      transient do
        previous_tied_judge { nil }
      end

      after(:create) do |vacols_case, evaluator|
        create(
          :case_hearing,
          :disposition_held,
          folder_nr: vacols_case.bfkey,
          hearing_date: 5.days.ago.to_date,
          user: evaluator.previous_tied_judge
        )
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

    trait :ready_for_distribution do
      status_active
      bfcurloc { "81" }
      bfdnod { 13.months.ago.to_date }
      bfd19 { 1.year.ago.to_date }
    end

    trait :with_appeal_affinity do
      transient do
        affinity_start_date { Time.zone.now }
      end

      after(:create) do |appeal, evaluator|
        create(:appeal_affinity, appeal: appeal, affinity_start_date: evaluator.affinity_start_date)
      end
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

    trait :disposition_ama do
      bfdc { "O" }
    end

    trait :disposition_advance_failure_to_respond do
      bfdc { "G" }
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

    trait :travel_board_hearing_requested do
      bfdocind { "T" }
      bfcurloc { "57" }
      bfhr { "2" }
      bfac { "1" }
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
        vacols_case.folder.update!(tivbms: %w[Y 1 0].sample)
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
      folder_number_equal { false }
      original_case { nil }

      after(:create) do |vacols_case, evaluator|
        if evaluator.folder_number_equal
          folder_json = evaluator.original_case.folder.to_json
          folder_attributes = JSON.parse(folder_json)
          folder_attributes.except!("bfkey", "ticknum", "tidrecv", "tidcls", "tiaduser",
                                    "tiadtime", "tikeywrd", "tiread2", "tioctime", "tiocuser",
                                    "tidktime", "tidkuser")
          vacols_case.folder.assign_attributes(folder_attributes)
          vacols_case.folder.save(validate: false)
        end
      end
    end

    transient do
      case_issues_equal { false }
      original_case_issues { [] }

      after(:create) do |vacols_case, evaluator|
        if evaluator.case_issues_equal
          evaluator.original_case_issues.each do |case_issue, i|
            vacols_case.case_issues[i] = case_issue.attributes.except("issaduser", "issadtime", "issmduser",
                                                                      "issmdtime", "issdc", "issdcls")
            vacols_case.case_issues[i].save
          end
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
